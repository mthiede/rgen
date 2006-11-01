$:.unshift File.join(File.dirname(__FILE__),"..","lib")
$:.unshift File.join(File.dirname(__FILE__),"..","test")

require 'test/unit'
require 'ea/xmi_class_instantiator'
require 'rgen/transformer'
require 'xmi_instantiator_test/class_model_checker'

class XmiClassInstantiatorTest < Test::Unit::TestCase

	MODEL_DIR = File.join(File.dirname(__FILE__),"xmi_instantiator_test")

	include ClassModelChecker
	
	def test_model
		envUML = RGen::Environment.new
		File.open(MODEL_DIR+"/testmodel.xml") { |f|
			XMIClassInstantiator.new.instantiateUMLClassModel(envUML, f.read)
		}
		checkClassModel(envUML)
	end


end