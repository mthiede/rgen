require 'rgen/xml_instantiator'
require 'rgen/environment'
require 'uml/uml_objectmodel'
require 'ea/xmi_metamodel'

# This module can be used to instantiate an UMLObjectModel from an XMI description.
# 
# Here is an example:
# 
# 	include XMIObjectInstantiator
# 	
# 	envUML = RGen::Environment.new
# 	File.open(MODEL_DIR+"/testmodel.xml") { |f|
# 		XMIClassInstantiator.new.instantiateUMLObjectModel(envUML, f.read)
# 	}
#
# 	# now use the newly created UML model
# 	envUML.find(:class => UMLObjectModel::UMLObject).each { |o|
# 		puts o.name
# 	}
#
# This module relies on XmiToObjectmodel to do the actual transformation.
# 
class XMIObjectInstantiator < RGen::XMLInstantiator
	
	include UMLObjectModel

	map_tag_ns "omg.org/UML1.3", XMIMetaModel::UML
	
	resolve_by_id :typeClass, :src => :type, :id => :xmi_id

	def initialize
		@envXMI = RGen::Environment.new 
		super(@envXMI, XMIMetaModel, true)
	end

	# This method does the actual work.
	def instantiateUMLObjectModel(envOut, str)
		instantiate(str)
				
		require 'ea/xmi_to_objectmodel'
		
		XmiToObjectmodel.new(@envXMI,envOut).transform
	end

end