$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'
require 'metamodels/uml13_metamodel'
require 'instantiators/ea_instantiator'
require 'rgen/serializer/xmi11_serializer'

class EASerializerTest < Test::Unit::TestCase

	MODEL_DIR = File.join(File.dirname(__FILE__),"testmodel")
	TEST_DIR = File.join(File.dirname(__FILE__),"ea_serializer_test")
  
	def test_serializer
		envUML = RGen::Environment.new
		File.open(MODEL_DIR+"/ea_testmodel.xml") { |f|
			inst = EAInstantiator.new(envUML, EAInstantiator::ERROR)
			inst.instantiate(f.read)
		}
    models = envUML.find(:class => UML13::Model)
    assert_equal 1, models.size
    
    File.open(TEST_DIR+"/ea_testmodel_regenerated.xml", "w") do |f|
      ser = RGen::Serializer::XMI11Serializer.new(f)
      ser.serialize(models.first, {:documentation => {:exporter => "Enterprise Architect", :exporterVersion => "2.5"}})
    end
	end
	
end