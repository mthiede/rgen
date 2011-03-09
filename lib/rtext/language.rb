require 'rgen/ecore/ecore'
require 'rgen/ecore/ecore_ext'
require 'rgen/serializer/opposite_reference_filter'
require 'rgen/serializer/qualified_name_provider'

module RText

class Language
  
  # Creates an RText language description for the metamodel described by +root_epackage+
  # Valid options include:
  #
  #  :feature_provider:
  #     a Proc which receives an EClass and should return a subset of this EClass's features
  #     this can be used to filter and/or reorder the features
  #     note that in most cases, this Proc will have to filter opposite references
  #     default: all features filtered using OppositeReferenceFilter 
  #
  #  :unlabled_arguments:
  #     a Proc which receives an EClass and should return this EClass's features which are to be
  #     serialized without lables in the given order and before all labled arguments
  #     the features must also occur in :feature_provider if :feature_provider is provided
  #     if unlabled arguments are not part of the current class's features, they will be ignored
  #     default: no unlabled arguments
  #
  #  :unquoted_arguments:
  #     a Proc which receives an EClass and should return this EClass's string typed attributes
  #     which are to be serialized without quotes
  #     note that the user must take care to use unquoted arguments only if the values are parsable without quotes
  #     the features must also occur in :feature_provider if :feature_provider is provided
  #     default: no unquoted arguments
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
  #  :identifier_provider:
  #     a Proc which receives an element and its containing element and should return 
  #     the element's identifier as a string
  #     default: identifiers calculated by QualifiedNameProvider
  #              in this case options to QualifiedNameProvider may be provided and will be passed through
  #
  #  :line_number_attribute:
  #     the name of the EAttribute which will be used to associate the line number with a model element
  #     default: no line number
  #
  #  :file_name_attribute:
  #     the name of the EAttribute which will be used to associate the file name with a model element
  #     default: no file name
  #
  #  :comment_handler: 
  #     a Proc which will be invoked when a new element has been instantiated
  #     receives an element and the comment as a string
  #     it should add the comment to the element and return true
  #     if the element can take no comment, it should return false
  #     default: no handling of comments 
  #  
  #  :comment_provider:
  #     a Proc which receives an element and should return this element's comment as a string or nil
  #     the Proc may also modify the element to remove information already part of the comment
  #     default: no comments
  #
  #  :indent_string:
  #     the string representing one indent, could be a tab or spaces
  #     default: 2 spaces
  #
  def initialize(root_epackage, options={})
    @root_epackage = root_epackage
    @feature_provider = options[:feature_provider] || 
      proc { |c| RGen::Serializer::OppositeReferenceFilter.call(c.eAllStructuralFeatures) }
    @unlabled_arguments = options[:unlabled_arguments]
    @unquoted_arguments = options[:unquoted_arguments]
    @command_classes = {}
    ((!options.has_key?(:short_class_names) || options[:short_class_names]) ?
      root_epackage.eAllClasses : root_epackage.eClasses).each do |c|
        raise "ambiguous class name #{c.name}" if @command_classes[c.name]
        @command_classes[c.name] = c.instanceClass
      end
    @reference_regexp = options[:reference_regexp] || /\A\w*(\/\w*)+/
    @identifier_provider = options[:identifier_provider] || 
      proc { |element, context|
        @qualified_name_provider ||= RGen::Serializer::QualifiedNameProvider.new(options)
        @qualified_name_provider.identifier(element)
      }
    @line_number_attribute = options[:line_number_attribute]
    @file_name_attribute = options[:file_name_attribute]
    @comment_handler = options[:comment_handler]
    @comment_provider = options[:comment_provider]
    @indent_string = options[:indent_string] || "  "
  end

  attr_reader :root_epackage
  attr_reader :command_classes
  attr_reader :reference_regexp
  attr_reader :identifier_provider
  attr_reader :line_number_attribute
  attr_reader :file_name_attribute
  attr_reader :comment_handler
  attr_reader :comment_provider
  attr_reader :indent_string

  def containments(clazz)
    features(clazz).select{|f| f.is_a?(RGen::ECore::EReference) && f.containment}
  end

  def non_containments(clazz)
    features(clazz).reject{|f| f.is_a?(RGen::ECore::EReference) && f.containment}
  end

  def labled_arguments(clazz)
    non_containments(clazz) - unlabled_arguments(clazz)
  end

  def unlabled_arguments(clazz)
    return [] unless @unlabled_arguments
    uargs = @unlabled_arguments.call(clazz) || []
    non_containments(clazz).select{|c| uargs.include?(c.name)}
  end

  def unquoted?(feature)
    return false unless @unquoted_arguments
    @unquoted_arguments.call(feature.eContainingClass).include?(feature.name)
  end

  def concrete_types(clazz)
    ([clazz] + clazz.eAllSubTypes).select{|c| !c.abstract}
  end

  def containments_by_target_type(clazz, type)
    map = {}
    clazz.eAllReferences.select{|r| r.containment}.each do |r|
      concrete_types(r.eType).each {|t| (map[t] ||= []) << r}
    end
    ([type]+type.eAllSuperTypes).inject([]){|m,t| m + (map[t] || []) }.uniq
  end

  def feature_by_name(clazz, name)
    clazz.eAllStructuralFeatures.find{|f| f.name == name}
  end

  private

  def features(clazz)
    @feature_provider.call(clazz)
  end

  # caching
  [ :containments,
    :non_containments,
    :unlabled_arguments,
    :labled_arguments,
    :unquoted?,
    :concrete_types,
    :containments_by_target_type,
    :feature_by_name
  ].each do |m|
    ms = m.to_s.sub('?','_')
    module_eval <<-END
      alias #{ms}_orig #{m}
      def #{m}(*args)
        @#{ms}_cache ||= {}
        return @#{ms}_cache[args] if @#{ms}_cache.has_key?(args)
        @#{ms}_cache[args] = #{ms}_orig(*args)
      end
    END
  end

end

end

