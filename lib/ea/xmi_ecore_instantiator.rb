require 'rgen/instantiator/default_xml_instantiator'
require 'rgen/environment'
require 'rgen/ecore/ecore'
require 'ea/xmi_metamodel'

# This module can be used to instantiate an ECore model from an XMI description.
# The input XMI is expected to be written by Enterprise Architect.
# 
# Here is an example:
# 
# 	envECore = RGen::Environment.new
# 	File.open(MODEL_DIR+"/testmodel.xml") { |f|
# 		XMIECoreInstantiator.new.instantiateECoreModel(envECore, f.read)
# 	}
#
# 	# now use the newly created ECore model
# 	envECore.find(:class => ECore::EClass).each { |c|
# 		puts c.name
# 	}
#
# This module relies on XmiToECore to do the actual transformation.
# 
class XMIECoreInstantiator < RGen::Instantiator::DefaultXMLInstantiator
		
	map_tag_ns "omg.org/UML1.3", XMIMetaModel::UML
	
	resolve_by_id :typeClass, :src => :type, :id => :xmi_id
	resolve_by_id :subtypeClass, :src => :subtype, :id => :xmi_id
	resolve_by_id :supertypeClass, :src => :supertype, :id => :xmi_id

	def initialize
		@envXMI = RGen::Environment.new 
		super(@envXMI, XMIMetaModel, true)
	end

	def new_object(node)
	 if node.tag == "EAStub"
	   class_name = saneClassName(node.attributes["UMLType"])
	   mod = XMIMetaModel::UML
		build_on_error(NameError, :build_class, class_name, mod) do
			mod.const_get(class_name).new
		end	 
      else
       super
	 end
	end	

	# This method does the actual work.
	def instantiateECoreModel(envOut, str)
		instantiate(str)

		require 'ea/xmi_to_ecore'
		
		XmiToECore.new(@envXMI,envOut).transform
	end

end