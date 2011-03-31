require 'rgen/ecore/ecore_ext'
require 'rgen/instantiator/reference_resolver'
require 'rtext/parser'

module RText

class Instantiator

  # A problem found during instantiation
  # if the file is not known, it will be nil
  InstantiatorProblem = Struct.new(:message, :file, :line)

  # Creates an instantiator for RText::Language +language+ 
  #
  def initialize(language)
    @lang = language
  end

  # instantiate +str+, +options+ include:
  #
  #  :env
  #    environment to which model elements will be added
  #
  #  :problems
  #    an array to which problems will be appended
  #  
  #  :unresolved_refs
  #    an array to which unresolved references will be appended
  # 
  #  :root_elements
  #    an array which will hold the root elements
  #
  #  :file_name
  #    name of the file being instantiated
  #
  def instantiate(str, options={})
    @line_numbers = {}
    @env = options[:env]
    @problems = options[:problems] || []
    @unresolved_refs = options[:unresolved_refs]
    @root_elements = options[:root_elements] || []
    @file_name = options[:file_name]
    parser = Parser.new(@lang.reference_regexp)
    begin
      @root_elements.clear
      parser.parse(str) do |*args|
        create_element(*args)
      end
    rescue Parser::Error => e
      problem(e.message, e.line)
    end
  end

  private

  def create_element(command, arg_list, element_list, comments, is_root)
    clazz = @lang.class_by_command(command.value)  
    if !clazz 
      problem("Unknown command '#{command.value}'", command.line)
      return
    end
    if clazz.ecore.abstract
      problem("Unknown command '#{command.value}' (metaclass is abstract)", command.line)
      return
    end
    element = clazz.new
    @env << element if @env
    @root_elements << element if is_root
    unlabled_args = @lang.unlabled_arguments(clazz.ecore).name
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
    set_file_name(element)
    if comments.size > 0
      add_comment(element, comments.collect{|c| c.value}.join("\n"))
    end
    element
  end

  def add_children(element, children, role, role_line)
    if role
      feature = @lang.feature_by_name(element.class.ecore, role)
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
      if !feature.many && 
        (element.getGenericAsArray(role).size > 0 || children.size > 1)
        problem("Only one child allowed in role '#{role}'", line_number(children[0]))
        return
      end
      expected_type = @lang.concrete_types(feature.eType)
      children.each do |c|
        if !expected_type.include?(c.class.ecore)
          problem("Role '#{role}' can not take a #{c.class.ecore.name}, expected #{expected_type.name.join(", ")}", line_number(c))
        else
          element.setOrAddGeneric(feature.name, c)
        end
      end
    else
      raise "if there is no role, children must not be an Array" if children.is_a?(Array)
      child = children
      return if child.nil?
      feature = @lang.containments_by_target_type(element.class.ecore, child.class.ecore)
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
        problem("Only one child allowed in role '#{feature.name}'", line_number(child))
        return
      end
      element.setOrAddGeneric(feature.name, child)
    end
  end

  def set_argument(element, name, value, defined_args, line)
    feature = @lang.feature_by_name(element.class.ecore, name)
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
        proxy = RGen::MetamodelBuilder::MMProxy.new(@lang.qualify_reference(v.value, element))
        if @unresolved_refs
          @unresolved_refs << 
            RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(element, feature.name, proxy)
        end
        element.setOrAddGeneric(feature.name, proxy)
      else
        element.setOrAddGeneric(feature.name, v.value)
      end
    end
    defined_args[name] = true
  end

  def add_comment(element, comment)
    if @lang.comment_handler && !@lang.comment_handler.call(element, comment)
      problem("This kind of element can not take a comment", line_number(element))
    end
  end

  def is_labeled(a)
    a.is_a?(Array) && a[0].respond_to?(:kind) && a[0].kind == :label
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
        RGen::ECore::EBoolean => [:boolean]
      }[feature.eType] 
    end
  end

  def set_line_number(element, line)
    @line_numbers[element] = line
    if @lang.line_number_attribute && element.respond_to?("#{@lang.line_number_attribute}=")
      element.send("#{@lang.line_number_attribute}=", line)
    end
  end

  def set_file_name(element)
    if @file_name && 
      @lang.file_name_attribute && element.respond_to?("#{@lang.file_name_attribute}=")
        element.send("#{@lang.file_name_attribute}=", @file_name)
    end
  end

  def line_number(e)
    @line_numbers[e]
  end

  def problem(msg, line)
    @problems << InstantiatorProblem.new(msg, @file_name, line) 
  end

end

end

