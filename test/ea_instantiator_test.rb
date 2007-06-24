$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'
require 'metamodels/uml13_metamodel'
require 'instantiators/ea_instantiator'
require 'transformers/uml13_to_ecore'
require 'testmodel/class_model_checker'
require 'testmodel/ecore_model_checker'

class EAInstantiatorTest < Test::Unit::TestCase

    include ClassModelChecker
    include ECoreModelChecker
    
	MODEL_DIR = File.join(File.dirname(__FILE__),"testmodel")
		
	def test_instantiator
		envUML = RGen::Environment.new
		File.open(MODEL_DIR+"/testmodel.xml") { |f|
			inst = EAInstantiator.new(envUML, EAInstantiator::ERROR)
			inst.instantiate(f.read)
		}
        checkClassModel(envUML)
        envECore = RGen::Environment.new
        UML13ToECore.new(envUML, envECore).transform
        checkECoreModel(envECore)
	end
	
	def test_partial
		envUML = RGen::Environment.new
		File.open(MODEL_DIR+"/testmodel_partial.xml") { |f|
			inst = EAInstantiator.new(envUML, EAInstantiator::ERROR)
			inst.instantiate(f.read)
		}
		checkClassModelPartial(envUML)
	end
end