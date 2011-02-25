require 'rgen/ecore/ecore'
require 'rgen/ecore/ecore_ext'
require 'rgen/serializer/opposite_reference_filter'
require 'rgen/serializer/qualified_name_provider'

module RGen

module Serializer

class TextSerializer

  # Creates a TextSerializer. Valid +options+ are:
  #
  #  :identifier_provider:
  #     a Proc which receives an element and its containing element and should return 
  #     the element's identifier as a string
  #     default: identifiers calculated by QualifiedNameProvider
  #              in this case options to QualifiedNameProvider may be provided and will 
  #              be passed through
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
  #  :comment_provider:
  #     a Proc which receives an element and should return this element's comment as a string or nil
  #     the Proc may also modify the element to remove information already part of the comment
  #     default: no comments
  #
  #   :indent_string:
  #     the string representing one indent, could be a tab or spaces
  #     default: 2 spaces
  #
  def initialize(options={})
    @qualified_name_provider = nil
    @identifier_provider = options[:identifier_provider] || 
      proc { |element, context|
        @qualified_name_provider ||= RGen::Serializer::QualifiedNameProvider.new(options)
        @qualified_name_provider.identifier(element)
      }
    @feature_provider = options[:feature_provider] || 
      proc { |c| OppositeReferenceFilter.call(c.eAllStructuralFeatures) }
    @unlabled_arguments = options[:unlabled_arguments]
    @unquoted_arguments = options[:unquoted_arguments]
    @comment_provider = options[:comment_provider]
    @indent_string = options[:indent_string] || "  "
    @containments_cache = {}
    @unlabled_arguments_cache = {}
    @labled_arguments_cache = {}
    @unlabled_arguments_cache = {}
    @needs_lable_cache = {}
    @unquoted_cache = {}
  end

  # Serialize +elements+ to +writer+
  def serialize(elements, writer)
    @writer = writer
    @indent = 0
    if elements.is_a?(Array)
      serialize_elements(elements)
    else
      serialize_elements([elements])
    end
  end

  private

  def serialize_elements(elements)
    elements.each do |e|
      serialize_element(e)
    end
  end
  
  def serialize_element(element)
    clazz = element.class.ecore
    # the comment provider may modify the element
    comment = @comment_provider && @comment_provider.call(element)
    if comment
      comment.split(/\r?\n/).each do |l|
        write("##{l}")
      end
    end
    headline = clazz.name
    args = []
    unlabled_arguments(clazz).each do |f|
      values = serialize_values(element, f)
      args << values if values
    end
    labled_arguments(clazz).each do |f|
      values = serialize_values(element, f)
      args << "#{f.name}: #{values}" if values
    end
    headline += " "+args.join(", ") if args.size > 0
    contained_elements = {}
    containments(clazz).each do |f|
      contained_elements[f] = element.getGenericAsArray(f.name) 
    end
    if contained_elements.values.any?{|v| v.size > 0}
      headline += " {"
      write(headline)
      iinc
      containments(clazz).each do |f|
        childs = contained_elements[f]
        if childs.size > 0
          if needs_lable?(f) 
            if childs.size > 1
              write("#{f.name}: [")
              iinc
              serialize_elements(childs)
              idec
              write("]")
            else
              write("#{f.name}:")
              iinc
              serialize_elements(childs)
              idec
            end
          else
            serialize_elements(childs)
          end
        end
      end
      idec
      write("}")
    else
      write(headline)
    end
  end

  def serialize_values(element, feature)
    values = element.getGenericAsArray(feature.name).compact
    result = []
    values.each do |v|
      if feature.eType == RGen::ECore::EInt
        result << v.to_s
      elsif feature.eType == RGen::ECore::EString
        if unquoted?(feature)
          result << v.to_s
        else
          result << "\"#{v.gsub("\\","\\\\\\\\").gsub("\"","\\\"").gsub("\n","\\n").
            gsub("\r","\\r").gsub("\t","\\t").gsub("\f","\\f").gsub("\b","\\b")}\""
        end
      elsif feature.eType == RGen::ECore::EBoolean
        result << v.to_s
      elsif feature.eType == RGen::ECore::EFloat
        result << v.to_s
      elsif feature.eType.is_a?(RGen::ECore::EEnum)
        result << v.to_s  
      elsif feature.is_a?(RGen::ECore::EReference)
        result << @identifier_provider.call(v, element) 
      end
    end
    if result.size > 1  
      "[#{result.join(", ")}]"
    elsif result.size == 1
      result.first 
    else
      nil
    end
  end

  def features(clazz)
    @feature_provider.call(clazz)
  end

  def non_containments(clazz)
    features(clazz).reject{|f| f.is_a?(RGen::ECore::EReference) && f.containment}
  end

  def containments(clazz)
    @containments_cache[clazz] ||= features(clazz).select do |f| 
      f.is_a?(RGen::ECore::EReference) && f.containment
    end
  end

  def unlabled_arguments(clazz)
    return @unlabled_arguments_cache[clazz] if @unlabled_arguments_cache[clazz] 
    if @unlabled_arguments
      @unlabled_arguments_cache[clazz] = (@unlabled_arguments.call(clazz) || []) & non_containments(clazz)
    else
      @unlabled_arguments_cache[clazz] = []
    end
  end

  def labled_arguments(clazz)
    @labled_arguments_cache[clazz] ||= non_containments(clazz) - unlabled_arguments(clazz)
  end

  def needs_lable?(feature)
    return @needs_lable_cache[feature] if @needs_lable_cache[feature]
    possible_types = [feature.eType]+feature.eType.eAllSubTypes
    @needs_lable_cache[feature] = 
      containments(feature.eContainingClass).any?{|f| f != feature && !(([f.eType]+f.eType.eAllSubTypes) & possible_types).empty?}
  end

  def unquoted?(feature)
    return @unquoted_cache[feature] if @unquoted_cache.has_key?(feature)
    @unquoted_cache[feature] = @unquoted_arguments && @unquoted_arguments.call(feature.eContainingClass).include?(feature)
  end

  def write(str)
    @writer.write(@indent_string * @indent + str + "\n")
  end

  def iinc
    @indent += 1
  end

  def idec
    @indent -= 1
  end
end

end

end


