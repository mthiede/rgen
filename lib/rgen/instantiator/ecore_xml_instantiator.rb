require 'rgen/ecore/ecore'
require 'rgen/instantiator/nodebased_xml_instantiator'
require 'rgen/array_extensions'

class ECoreXMLInstantiator < RGen::Instantiator::NodebasedXMLInstantiator
	
	include RGen::ECore
	
	def on_descent(node)
		obj = new_object(node)
		@env << obj unless obj.nil?
		node.object = obj
		node.attributes.each_pair { |k,v| set_attribute(node, k, v) }
	end

	def on_ascent(node)
		node.children.each { |c| assoc_p2c(node, c) }
	end

	def new_object(node)
		if node.attributes["xsi:type"] && node.attributes["xsi:type"] =~ /ecore:(\w+)/
			class_name = $1
			node.attributes.delete("xsi:type")
		else 
		  eRef = node.parent && node.parent.object.class.ecore.eAllReferences.find{|r|r.name == node.tag}
		  if eRef
		    class_name = eRef.eType.name
		  else
			class_name = node.tag
          end
		end
	  eClass = RGen::ECore.ecore.eClassifiers.find{|c| c.name == class_name}
		return unless eClass
		RGen::ECore.const_get(class_name).new
	end

	def assoc_p2c(parent, child)
		return unless parent.object
		parent.object.addGeneric(child.tag, child.object)
	end

	ResolverDescription = Struct.new(:object, :attribute, :value)
		
	def set_attribute(node, attr, value)
	  return unless node.object
		if value =~ /^#.*/
			rd = ResolverDescription.new
			rd.object = node.object
			rd.attribute = attr
			rd.value = value
			@resolver_descs << rd
			return
		end
	  eAttr = node.object.class.ecore.eAllAttributes.find{|a| a.name == attr}
	 	return unless eAttr
	 	value = true if value == "true" && eAttr.eType == EBoolean
	 	value = false if value == "false" && eAttr.eType == EBoolean
		value = value.to_i if eAttr.eType == EInt
		node.object.setGeneric(attr, value)
	end
	
	def instantiate(str)
		@resolver_descs = []
		super
		rootpackage = @env.find(:class => EPackage).first
		@resolver_descs.each do |rd|
			refed = find_referenced(rootpackage, rd.value)
			feature = rd.object.class.ecore.eAllStructuralFeatures.find{|f| f.name == rd.attribute}
			raise StandardError.new("StructuralFeature not found: #{rd.attribute}") unless feature
			if feature.many
				rd.object.setGeneric(feature.name, refed)
			else
				rd.object.setGeneric(feature.name, refed.first)
			end
		end
	end
	
	def find_referenced(context, desc)
		desc.split(/\s+/).collect do |r|
			if r =~ /^#\/\/([\w\/]+)/
				find_in_context(context, $1.split('/'))
			end
		end.compact
	end
		
	def find_in_context(context, desc_elements)
		if context.is_a?(EPackage)
			r = context.eClassifiers.find{|c| c.name == desc_elements.first}
		elsif context.is_a?(EClass)
			r = context.eStructuralFeatures.find{|s| s.name == desc_elements.first}
		else
			raise StandardError.new("Don't know how to find #{desc_elements.join('/')} in context #{context}")
		end
		if desc_elements.size > 1
			find_in_context(r, desc_elements[1..-1])
		else
			r
		end
	end
end