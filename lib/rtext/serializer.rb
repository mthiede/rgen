require 'rtext/language'

module RText

class Serializer

  # Creates a serializer for RText::Language +language+.
  #
  def initialize(language)
    @lang = language
  end

  # Serialize +elements+ to +writer+. Options:
  #
  #  :set_line_number
  #    if set to true, the serializer will try to update the line number attribute of model
  #    elements, while they are serialized, given that they have the line_number_attribute
  #    specified in the RText::Language
  #    default: don't set line number
  #
  #  :fragment_ref
  #    an object referencing a fragment, this will be set on all model elements while they
  #    are serialized, given that they have the fragment_ref_attribute specified in the
  #    RText::Language
  #    default: don't set fragment reference
  #
  def serialize(elements, writer, options={})
    @writer = writer
    @set_line_number = options[:set_line_number]
    @fragment_ref = options[:fragment_ref]
    @line_number = 1
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
    set_fragment_ref(element)
    set_line_number(element, @line_number) if @set_line_number
    clazz = element.class.ecore
    # the comment provider may modify the element
    comment = @lang.comment_provider && @lang.comment_provider.call(element)
    if comment
      comment.split(/\r?\n/).each do |l|
        write("##{l}")
      end
    end
    headline = clazz.name
    args = []
    @lang.unlabled_arguments(clazz).each do |f|
      values = serialize_values(element, f)
      args << values if values
    end
    @lang.labled_arguments(clazz).each do |f|
      values = serialize_values(element, f)
      args << "#{f.name}: #{values}" if values
    end
    headline += " "+args.join(", ") if args.size > 0
    contained_elements = {}
    @lang.containments(clazz).each do |f|
      contained_elements[f] = element.getGenericAsArray(f.name) 
    end
    if contained_elements.values.any?{|v| v.size > 0}
      headline += " {"
      write(headline)
      iinc
      @lang.containments(clazz).each do |f|
        childs = contained_elements[f]
        if childs.size > 0
          if @lang.containments_by_target_type(f.eContainingClass, f.eType).size > 1
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
        if @lang.unquoted?(feature)
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
        result << @lang.identifier_provider.call(v, element) 
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

  def set_line_number(element, line)
    if @lang.line_number_attribute && element.respond_to?("#{@lang.line_number_attribute}=")
      element.send("#{@lang.line_number_attribute}=", line)
    end
  end

  def set_fragment_ref(element)
    if @fragment_ref && 
      @lang.fragment_ref_attribute && element.respond_to?("#{@lang.fragment_ref_attribute}=")
        element.send("#{@lang.fragment_ref_attribute}=", @fragment_ref)
    end
  end

  def write(str)
    @writer.write(@lang.indent_string * @indent + str + "\n")
    @line_number += 1
  end

  def iinc
    @indent += 1
  end

  def idec
    @indent -= 1
  end
end

end


