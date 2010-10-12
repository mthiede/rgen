$:.unshift File.dirname(__FILE__) + "/../lib"

require 'test/unit'
require 'rgen/ecore/ecore'

# The following would also influence other tests...
#
#module RGen::ECore
#  class EGenericType < EObject
#    contains_many_uni 'eTypeArguments', EGenericType
#  end
#  class ETypeParameter < ENamedElement
#  end
#  class EClassifier
#    contains_many_uni 'eTypeParameters', ETypeParameter
#  end
#  class ETypedElement
#    has_one 'eGenericType', EGenericType
#  end
#end
#
#RGen::ECore::ECoreInstantiator.clear_ecore_cache
#RGen::ECore::EString.ePackage = RGen::ECore.ecore

require 'rgen/environment'
require 'rgen/model_builder/model_serializer'
require 'rgen/instantiator/ecore_xml_instantiator'
require 'rgen/model_builder'
require 'model_builder/statemachine_metamodel'

class ModelSerializerTest < Test::Unit::TestCase
  def test_ecore_internal
    File.open(File.dirname(__FILE__)+"/ecore_internal.rb","w") do |f|
      serializer = RGen::ModelBuilder::ModelSerializer.new(f, RGen::ECore.ecore)
      serializer.serialize(RGen::ECore.ecore)
    end
  end
  
  def test_roundtrip
    testModel = %{\
statemachine "Airconditioner" do
  state "Off", :kind => :START
  compositeState "On" do
    state "Heating", :outgoingTransition => ["_Transition2"], :incomingTransition => ["_Transition1"]
    state "Cooling", :outgoingTransition => ["_Transition1"], :incomingTransition => ["_Transition2"]
    state "Dumm"
  end
  transition "_Transition1"
  transition "_Transition2"
end
}
    sm = RGen::ModelBuilder.build(StatemachineMetamodel) do
      eval(testModel)
    end
    f = StringIO.new
    serializer = RGen::ModelBuilder::ModelSerializer.new(f, StatemachineMetamodel.ecore)
    serializer.serialize(sm)
    assert_equal testModel, f.string
  end
  
end
