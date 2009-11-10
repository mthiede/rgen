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
  
  def xxx_test_ecore_original
    env = RGen::Environment.new
    File.open(File.dirname(__FILE__)+"/Ecore.ecore") { |f|
      ECoreXMLInstantiator.new(env,ECoreXMLInstantiator::ERROR).instantiate(f.read)
    }
    serializeEcore(env, "ecore", File.dirname(__FILE__)+"/ecore_original.rb")
    b = nil
    env2 = RGen::Environment.new
    RGen::ModelBuilder.build(RGen::ECore, env2) do
      b = binding
    end
    File.open(File.dirname(__FILE__)+"/ecore_original.rb") do |f|
      eval(f.read, b)
    end
    serializeEcore(env2, "ecore", File.dirname(__FILE__)+"/ecore_original_regenerated.rb")    
  end
  
  def serializeEcore(env, rootPackageName, fileName)
    env.find(:class => RGen::ECore::EClass).each {|c| c.eOperations = []}
    env.find(:class => RGen::ECore::EModelElement).each {|e| e.eAnnotations = []}
    File.open(fileName,"w") do |f|
      serializer = RGen::ModelBuilder::ModelSerializer.new(f, RGen::ECore.ecore)
      serializer.serialize(env.find(:class => RGen::ECore::EPackage, :name => rootPackageName))
    end
  end
end