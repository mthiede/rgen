require 'rgen/serializer/xml_serializer'

module RGen

module Serializer

class XMI20Serializer < XMLSerializer

	def serialize(rootElement)
		buildReferenceStrings(rootElement, "#/")
		attrs = attributeHash(rootElement)
		attrs['xmi:version'] = "2.0"
		attrs['xmlns:xmi'] = "http://www.omg.org/XMI"
		attrs['xmlns:xsi'] = "http://www.w3.org/2001/XMLSchema-instance"
		attrs['xmlns:ecore'] = "http://www.eclipse.org/emf/2002/Ecore" 
		tag = "ecore:"+rootElement.class.ecore.name
		startTag(tag, attrs)
		writeComposites(rootElement)
		endTag(tag)
	end
	
	def writeComposites(element)
		eachReferencedElement(element, containmentReferences(element)) do |r,te|
			attrs = attributeHash(te)
			attrs['xsi:type'] = "ecore:"+te.class.ecore.name
			tag = r.name
			startTag(tag, attrs)
			writeComposites(te)
			endTag(tag)
		end
	end

	def attributeHash(element)
		result = {}
		eAllAttributes(element).select{|a| !a.derived}.each do |a|
			val = element.getGeneric(a.name)
			result[a.name] = val unless val.nil? || val == ""
		end
		eAllReferences(element).select{|r| !r.containment && !r.derived}.each do |r|
			targetElements = element.getGeneric(r.name)
			targetElements = [targetElements] unless targetElements.is_a?(Array)
			val = targetElements.collect{|te| @referenceStrings[te]}.compact.join(' ')
			result[r.name] = val unless val.nil? || val == ""
		end
		result	
	end
	
	def buildReferenceStrings(element, string)
		@referenceStrings ||= {}
		@referenceStrings[element] = string
		eachReferencedElement(element, containmentReferences(element)) do |r,te|
			buildReferenceStrings(te, string+"/"+te.name) if te.respond_to?(:name)
		end
	end

end

end

end