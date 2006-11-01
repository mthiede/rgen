$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'ea/xmi_class_instantiator'
require 'mmgen/metamodel_generator'

class MetamodelGeneratorTest < Test::Unit::TestCase

	MODEL_DIR = File.join(File.dirname(__FILE__),"xmi_instantiator_test")
	OUTPUT_DIR = File.dirname(__FILE__)+"/metamodel_generator_test"
	MM_FILE = OUTPUT_DIR+"/TestModel.rb"
	
	include MMGen::MetamodelGenerator
		
	def test_generator
		envUML = RGen::Environment.new
		File.open(MODEL_DIR+"/testmodel.xml") { |f|
			XMIClassInstantiator.new.instantiateUMLClassModel(envUML, f.read)
		}

		rootPackage = envUML.find(:class => UMLClassModel::UMLPackage).select{|p| p.name == "HouseMetamodel"}.first
		assert_not_nil rootPackage
		
		assert_raise StandardError do
			# this will raise an exception because multiple inheritance is not resolved
			generateMetamodel(rootPackage, MM_FILE)
		end
		
		# resolve multiple inheritance by specifying which class should be a module
		modules = ['MeetingPlace']
		generateMetamodel(rootPackage, MM_FILE, modules)
		
		# try to use the generated metamodel
		File.open(MM_FILE) { |f|
			eval(f.read)
		}
		assert HouseMetamodel::House.new

		result = expected = ""
		File.open(MM_FILE) {|f| result = f.read}
		File.open(OUTPUT_DIR+"/expected_result.txt") {|f| expected = f.read}
		assert_equal expected, result
	end
end