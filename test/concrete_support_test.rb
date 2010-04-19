$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'
require 'concrete_support/concrete_mmm'
require 'concrete_support/ecore_to_concrete'
require 'concrete_support/json_serializer'
require 'concrete_support/json_instantiator'

class ConcreteSupportTest < Test::Unit::TestCase
  include ConcreteSupport

  def test_ecore_to_concrete
    env = RGen::Environment.new
    outfile = File.dirname(__FILE__)+"/concrete_support_test/concrete_mmm_generated.js"
    ECoreToConcrete.new(nil, env).trans(ConcreteMMM.ecore.eClasses)
    File.open(outfile, "w") do |f|
      ser = JsonSerializer.new(f)
      ser.serialize(env.find(:class => ConcreteMMM::Classifier))        
    end
  end

  def test_json_instantiator
    infile = File.dirname(__FILE__)+"/concrete_support_test/concrete_mmm_generated.js"
    env = RGen::Environment.new
    inst = JsonInstantiator.new(env, ConcreteMMM)
    inst.instantiate(File.read(infile))
    File.open(infile.sub(".js",".regenerated.js"), "w") do |f|
      ser = JsonSerializer.new(f, :identifierProvider => proc{|e| e.is_a?(RGen::MetamodelBuilder::MMProxy) && "xxx"})
      ser.serialize(env.find(:class => ConcreteMMM::Class))        
    end
  end

  module TestMM
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
      has_attr 'integer', Integer
      has_attr 'float', Float
      contains_many 'childs', TestNode, 'parent'
    end
  end

  class StringWriter < String
    alias write concat
  end

  def test_json_serializer
    testModel = TestMM::TestNode.new(:text => "some text", :childs => [
      TestMM::TestNode.new(:text => "child")])

    output = StringWriter.new
    ser = JsonSerializer.new(output)

    assert_equal %q({ "_class": "TestNode", "text": "some text", "childs": [ 
  { "_class": "TestNode", "text": "child" }] }), ser.serialize(testModel)
  end

  def test_json_serializer_escapes
    testModel = TestMM::TestNode.new(:text => %q(some " \ \" text))
    output = StringWriter.new
    ser = JsonSerializer.new(output)

    assert_equal %q({ "_class": "TestNode", "text": "some \" \\ \\\" text" }), ser.serialize(testModel) 
  end
   
  def test_json_instantiator_escapes
    env = RGen::Environment.new
    inst = JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "text": "some \" \\ \\\\\" text" }))
    assert_equal %q(some " \ \" text), env.elements.first.text
  end

  def test_json_serializer_integer
    testModel = TestMM::TestNode.new(:integer => 7)
    output = StringWriter.new
    ser = JsonSerializer.new(output)
    assert_equal %q({ "_class": "TestNode", "integer": 7 }), ser.serialize(testModel) 
  end

  def test_json_instantiator_integer
    env = RGen::Environment.new
    inst = JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "integer": 7 }))
    assert_equal 7, env.elements.first.integer
  end

  def test_json_serializer_float
    testModel = TestMM::TestNode.new(:float => 1.23)
    output = StringWriter.new
    ser = JsonSerializer.new(output)
    assert_equal %q({ "_class": "TestNode", "float": 1.23 }), ser.serialize(testModel) 
  end

  def test_json_instantiator_float
    env = RGen::Environment.new
    inst = JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "float": 1.23 }))
    assert_equal 1.23, env.elements.first.float
  end
end
	
