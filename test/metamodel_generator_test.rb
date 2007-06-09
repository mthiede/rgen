$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'ea/xmi_ecore_instantiator'
require 'mmgen/metamodel_generator'

class MetamodelGeneratorTest < Test::Unit::TestCase

	MODEL_DIR = File.join(File.dirname(__FILE__),"xmi_instantiator_test")
	OUTPUT_DIR = File.dirname(__FILE__)+"/metamodel_generator_test"
	MM_FILE = OUTPUT_DIR+"/TestModel.rb"
	MM_FILE2 = OUTPUT_DIR+"/TestModel2.rb"
	
	include MMGen::MetamodelGenerator
		
	def test_generator
		env = RGen::Environment.new
		File.open(MODEL_DIR+"/testmodel.xml") { |f|
			XMIECoreInstantiator.new.instantiateECoreModel(env, f.read)
		}

		rootPackage = env.find(:class => RGen::ECore::EPackage).select{|p| p.name == "HouseMetamodel"}.first
		assert_not_nil rootPackage
		
		# add some more specific attributes to check the generator
		house = env.find(:class => RGen::ECore::EClass, :name => "House")
		house.eAttributes.first.changeable = false
		
		generateMetamodel(rootPackage, MM_FILE)
		
		# try to use the generated metamodel
		File.open(MM_FILE) { |f|
			eval(f.read)
		}
        assert HouseMetamodel::House.ecore.is_a?(RGen::ECore::EClass)

        # TODO: now do it again using the ecore built up from generated code
		# generateMetamodel(HouseMetamodel::House.ecore.ePackage, MM_FILE2, modules)

		result = expected = ""
		File.open(MM_FILE) {|f| result = f.read}
		File.open(OUTPUT_DIR+"/expected_result.txt") {|f| expected = f.read}
		assert_equal expected, result
	end
end