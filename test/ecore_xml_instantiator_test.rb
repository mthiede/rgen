$:.unshift File.join(File.dirname(__FILE__),"..","lib")
$:.unshift File.join(File.dirname(__FILE__),"..","test")

require 'test/unit'
require 'rgen/environment'
require 'rgen/ecore/ecore'
require 'rgen/model_dumper'
require 'rgen/instantiator/ecore_xml_instantiator'
require 'mmgen/metamodel_generator'

TOP_LEVEL_BINDING = binding

class ECoreXMLInstantiatorTest < Test::Unit::TestCase

	MODEL_DIR = File.join(File.dirname(__FILE__),"ecore_xml_instantiator_test")
	MM_FILE = MODEL_DIR+"/uml13_metamodel.rb"

	include MMGen::MetamodelGenerator

	def test_model
		env = RGen::Environment.new
		File.open(MODEL_DIR+"/uml13.ecore") { |f|
			ECoreXMLInstantiator.new(env).instantiate(f.read)
		}
		rootpackage = env.find(:class => RGen::ECore::EPackage).first
		rootpackage.name = "UML13"
		generateMetamodel(rootpackage, MM_FILE)

        File.open(MM_FILE) do |f|
          eval(f.read, TOP_LEVEL_BINDING, "test_eval", 0)
        end
	end

end