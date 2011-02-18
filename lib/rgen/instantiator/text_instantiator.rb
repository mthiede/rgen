require 'rgen/ecore/ecore_ext'
require 'rgen/instantiator/text_parser'

module RGen

module Instantiator

class TextInstantiator

  # Creates a TextInstantiator. Valid +options+ are:
  #
  #  :unlabled_arguments: 
  #     a Proc which receives an EClass and should return the names of the features which are expected
  #     to be serialized without lables in the given order and before all labled arguments
  #     default: no unlabled arguments
  #
  #  :comment_handler: 
  #     a Proc which will be invoked when a new element has been instantiated
  #     receives an element and the comment as a string
  #     it should add the comment to the element and return true
  #     if the element can take no comment, it should return false
  #     default: no handling of comments 
  #  
  #  :line_number_setter:
  #     the name of a method which will be called on each element to set the line number (e.g. :line=)
  #     if the method is not present on an element, no line number will be set
  #     default: no line number setting
  #
  #  :short_class_names:
  #     if true, the metamodel is searched for classes by unqualified class name recursively
  #     if false, classes can only be found in the root package, not in subpackages 
  #     default: true
  #
  #  :reference_regexp:
  #     a Regexp which is used by the tokenizer for identifying references 
  #     it must only match at the beginning of a string, i.e. it should start with \A
  #     it must be built in a way that does not match other language constructs
  #     in particular it must not match identifiers (word characters not starting with a digit)
  #     identifiers can always be used where references are expected
  #     default: word characters separated by at least one slash (/) 
  #     
  #
  def initialize(env, mm, options={})
    @env = env
    @unlabled_arguments = options[:unlabled_arguments]
    @comment_handler = options[:comment_handler]
    @line_number_setter = options[:line_number_setter]
    @reference_regexp = options[:reference_regexp] || /\A\w*(\/\w*)+/
    @classes = {}
    ((!options.has_key?(:short_class_names) || options[:short_class_names]) ?
      mm.ecore.eAllClasses : mm.ecore.eClasses).each do |c|
        raise "ambiguous class name #{c.name}" if @classes[c.name]
        @classes[c.name] = c.instanceClass
      end
    @unlabled_arguments_cache = {}
    @feature_by_name_cache = {}
    @valid_target_types_cache = {}
    @containment_by_target_type_cache = {}
  end

  def instantiate(str, problems=[])
    @line_numbers = {}
    @problems = problems
    parser = Parser.new(@reference_regexp)
    begin
      parser.parse(str) do |*args|
        create_element(*args)
      end
    rescue Parser::Error => e
      problem(e.message, e.line)
    end
  end

  def create_element(command, arg_list, element_list, comments)
    clazz = @classes[command.value]  
    if !clazz 
      problem("Unknown command '#{command.value}'", command.line)
      return
    end
    if clazz.ecore.abstract
      problem("Unknown command '#{command.value}' (metaclass is abstract)", command.line)
      return
    end
    element = @env.new(clazz)
    unlabled_args = unlabled_arguments(clazz.ecore)
    di_index = 0
    defined_args = {}
    arg_list.each do |a|
      if is_labeled(a) 
        set_argument(element, a[0].value, a[1], defined_args, command.line)
      else
        if di_index < unlabled_args.size 
          set_argument(element, unlabled_args[di_index], a, defined_args, command.line)
          di_index += 1
        else
          problem("Unexpected unlabled argument, #{unlabled_args.size} unlabled arguments expected", command.line)
        end
      end
    end
    element_list.each do |e|
      if is_labeled(e)
        add_children(element, e[1], e[0].value, e[0].line)
      else
        add_children(element, e, nil, nil)
      end
    end
    set_line_number(element, command.line)
    if comments.size > 0
      add_comment(element, comments.collect{|c| c.value}.join("\n"))
    end
    element
  end

  def add_children(element, children, role, role_line)
    if role
      feature = feature_by_name(element.class.ecore, role)
      if !feature
        problem("Unknown child role '#{role}'", role_line)
        return
      end
      if !feature.is_a?(RGen::ECore::EReference) || !feature.containment
        problem("Role '#{role}' can not take child elements", role_line)
        return
      end
      children = [children] unless children.is_a?(Array)
      children.compact!
      if children.size == 0
        return
      end
      if element.getGenericAsArray(role).size > 0 && !feature.many
        problem("Only one child allowed in role #{role}", line_number(children[0]))
        return
      end
      expected_type = valid_target_types(feature)
      children.each do |c|
        if !expected_type.include?(c.class.ecore)
          problem("Role #{role} can not take a #{c.class.ecore.name}, expected #{expected_type.name.join(", ")}", line_number(c))
        else
          element.setOrAddGeneric(feature.name, c)
        end
      end
    else
      raise "if there is no role, children must not be an Array" if children.is_a?(Array)
      child = children
      return if child.nil?
      feature = containment_by_target_type(element.class.ecore, child.class.ecore)
      if feature.size == 0
        problem("This kind of element can not be contained here", line_number(child))
        return
      end
      if feature.size > 1
        problem("Role of element is ambiguous, use a role label", line_number(child))
        return
      end
      feature = feature[0]
      if element.getGenericAsArray(feature.name).size > 0 && !feature.many
        problem("Only one child allowed in role #{feature.name}", line_number(child))
        return
      end
      element.setOrAddGeneric(feature.name, child)
    end
  end

  def set_argument(element, name, value, defined_args, line)
    feature = feature_by_name(element.class.ecore, name)
    if !feature
      problem("Unknown argument '#{name}'", line)
      return
    end
    if feature.is_a?(RGen::ECore::EReference) && feature.containment
      problem("Argument '#{name}' can only take child elements", line)
      return
    end
    if defined_args[name]
      problem("Argument '#{name}' already defined", line)
      return
    end
    value = [value] unless value.is_a?(Array)
    if value.size > 1 && !feature.many
      problem("Argument '#{name}' can take only one value", line)
      return
    end
    expected_kind = expected_token_kind(feature)
    value.each do |v|
      if !expected_kind.include?(v.kind)
        problem("Argument '#{name}' can not take a #{v.kind}, expected #{expected_kind.join(", ")}", line)
      elsif feature.eType.is_a?(RGen::ECore::EEnum) 
        if !feature.eType.eLiterals.name.include?(v.value)
          problem("Argument '#{name}' can not take value #{v.value}, expected #{feature.eType.eLiterals.name.join(", ")}", line)
        else
          element.setOrAddGeneric(feature.name, v.value.to_sym)
        end
      elsif feature.is_a?(RGen::ECore::EReference)
        element.setOrAddGeneric(feature.name, RGen::MetamodelBuilder::MMProxy.new(v.value))
      else
        element.setOrAddGeneric(feature.name, v.value)
      end
    end
    defined_args[name] = true
  end

  def add_comment(element, comment)
    if @comment_handler && !@comment_handler.call(element, comment)
      problem("This kind of element can not take a comment", line_number(element))
    end
  end

  def is_labeled(a)
    a.is_a?(Array) && a[0].respond_to?(:kind) && a[0].kind == :label
  end

  def containment_by_target_type(clazz, type)
    return @containment_by_target_type_cache[[clazz, type]] \
      if @containment_by_target_type_cache[[clazz, type]]
    map = {}
    clazz.eAllReferences.select{|r| r.containment}.each do |r|
      valid_target_types(r).each do |t|
        map[t] ||= []
        map[t] << r
      end
    end
    @containment_by_target_type_cache[[clazz, type]] =
      ([type]+type.eAllSuperTypes).inject([]){|m,t| m + (map[t] || []) }
  end

  def valid_target_types(feature)
    @valid_target_types_cache[feature] ||=
      ([feature.eType] + feature.eType.eAllSubTypes).select{|t| !t.abstract}
  end

  def feature_by_name(clazz, name)
    @feature_by_name_cache[[clazz, name]] ||=
      clazz.eAllStructuralFeatures.find{|f| f.name == name}
  end

  def expected_token_kind(feature)
    if feature.is_a?(RGen::ECore::EReference)
      [:reference, :identifier]
    elsif feature.eType.is_a?(RGen::ECore::EEnum)
      [:identifier]
    else
      { RGen::ECore::EString => [:string, :identifier],
        RGen::ECore::EInt => [:integer],
        RGen::ECore::EFloat => [:float],
        RGen::ECore::EBoolean => [:true, :false],
      }[feature.eType] 
    end
  end

  def unlabled_arguments(clazz)
    @unlabled_arguments_cache[clazz] ||=
      @unlabled_arguments ? (@unlabled_arguments[clazz] || []) : []
  end

  def set_line_number(element, line)
    @line_numbers[element] = line
    if @line_number_setter && element.respond_to?(@line_number_setter)
      element.send(@line_number_setter, line)
    end
  end

  def line_number(e)
    @line_numbers[e]
  end

  def problem(msg, line)
    @problems << [msg, line] 
  end

end

end

end


