$:.unshift File.join(File.dirname(__FILE__),"..","lib")
$:.unshift File.join(File.dirname(__FILE__),"..","test")

require 'test/unit'
require 'ea/xmi_ecore_instantiator'
require 'rgen/transformer'
require 'xmi_instantiator_test/ecore_model_checker'

class XmiECoreInstantiatorTest < Test::Unit::TestCase

	MODEL_DIR = File.join(File.dirname(__FILE__),"xmi_instantiator_test")

	include ECoreModelChecker
	
	def test_model
		envECore = RGen::Environment.new
		File.open(MODEL_DIR+"/testmodel.xml") { |f|
			XMIECoreInstantiator.new.instantiateECoreModel(envECore, f.read)
		}
		checkECoreModel(envECore)
	end


end