require 'rgen/xml_instantiator'
require 'rgen/environment'
require 'uml/uml_classmodel'
require 'ea/xmi_metamodel'

# This module can be used to instantiate an UMLClassModel from an XMI description.
# 
# Here is an example:
# 
# 	envUML = RGen::Environment.new
# 	File.open(MODEL_DIR+"/testmodel.xml") { |f|
# 		XMIClassInstantiator.new.instantiateUMLClassModel(envUML, f.read)
# 	}
#
# 	# now use the newly created UML model
# 	envUML.find(:class => UMLClassModel::UMLClass).each { |c|
# 		puts c.name
# 	}
#
# This module relies on XmiToClassmodel to do the actual transformation.
# 
class XMIClassInstantiator < RGen::XMLInstantiator
	
	include UMLClassModel
	
	map_tag_ns "omg.org/UML1.3", XMIMetaModel::UML
	
	resolve_by_id :typeClass, :src => :type, :id => :xmi_id
	resolve_by_id :subtypeClass, :src => :subtype, :id => :xmi_id
	resolve_by_id :supertypeClass, :src => :supertype, :id => :xmi_id

	def initialize
		@envXMI = RGen::Environment.new 
		super(@envXMI, XMIMetaModel, true)
	end
	
	# This method does the actual work.
	def instantiateUMLClassModel(envOut, str)
		instantiate(str)

		require 'ea/xmi_to_classmodel'
		
		XmiToClassmodel.new(@envXMI,envOut).transform
	end

end