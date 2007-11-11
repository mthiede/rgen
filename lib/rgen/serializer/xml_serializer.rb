module RGen

module Serializer

class XMLSerializer

	def initialize
		@output = ""
	end
	
	def result
		@output
	end
	
	def serialize(rootElement)
		raise "Abstract class, overwrite method in subclass!"
	end
	
	def startTag(tag, attributes, indent)
		@output += "  "*indent + "<#{tag} " + attributes.keys.collect{|k| "#{k}=\"#{attributes[k]}\""}.join(" ") + ">\n"
	end

	def endTag(tag, indent)
		@output += "  "*indent + "</#{tag}>\n"
	end
	
	protected

  def eAllReferences(element)
    @eAllReferences ||= {}
    @eAllReferences[element.class] ||= element.class.ecore.eAllReferences
  end

  def eAllAttributes(element)
    @eAllAttributes ||= {}
    @eAllAttributes[element.class] ||= element.class.ecore.eAllAttributes
  end
    
  def eAllStructuralFeatures(element)
    @eAllStructuralFeatures ||= {}
    @eAllStructuralFeatures[element.class] ||= element.class.ecore.eAllStructuralFeatures
  end

	def eachReferencedElement(element, refs, &block)
		refs.each do |r|
			targetElements = element.getGeneric(r.name)
			targetElements = [targetElements] unless targetElements.is_a?(Array)
			targetElements.each do |te|
				yield(r,te)
			end
		end			
	end  

  def containmentReferences(element)
  	eAllReferences(element).select{|r| r.containment}
  end
end

end

end
