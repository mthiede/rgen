module RGen

module Serializer

# simple identifier calculation based on qualified names
# prerequisits:
# * containment relations must be bidirectionsl
# * local name stored in single attribute +@attribute_name+ for all classes
#
class QualifiedNameProvider

  def initialize(options={})
    @qualified_name_cache = {}
    @attribute_name = options[:attribute_name] || "name"
    @separator = options[:separator] || "/"
    @leading_separator = options.has_key?(:leading_separator) ? options[:leading_separator] : true 
  end

  def identifier(element)
    (element.is_a?(RGen::MetamodelBuilder::MMProxy) && element.targetIdentifier) || qualified_name(element)
  end

  def qualified_name(element)
    return @qualified_name_cache[element] if @qualified_name_cache[element]
    localIdent = ((element.respond_to?(@attribute_name) && element.getGeneric(@attribute_name)) || "").strip
    parentRef = element.class.ecore.eAllReferences.select{|r| r.eOpposite && r.eOpposite.containment}.first
    parent = parentRef && element.getGeneric(parentRef.name)
    if parent
      if localIdent.size > 0
        parentIdent = qualified_name(parent)
        result = parentIdent + @separator + localIdent
      else
        result = qualified_name(parent)
      end
    else
      result = (@leading_separator ? @separator : "") + localIdent
    end
    @qualified_name_cache[element] = result
  end
end

end

end

