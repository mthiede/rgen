$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'
require 'rgen/metamodel_builder'
require 'rgen/serializer/json_serializer'
require 'rgen/instantiator/json_instantiator'

class JsonTest < Test::Unit::TestCase

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
    ser = RGen::Serializer::JsonSerializer.new(output)

    assert_equal %q({ "_class": "TestNode", "text": "some text", "childs": [ 
  { "_class": "TestNode", "text": "child" }] }), ser.serialize(testModel)
  end

  def test_json_instantiator
    env = RGen::Environment.new
    inst = RGen::Instantiator::JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "text": "some text", "childs": [ 
  { "_class": "TestNode", "text": "child" }] }))
    root = env.find(:class => TestMM::TestNode, :text => "some text").first
    assert_not_nil root
    assert_equal 1, root.childs.size
    assert_equal TestMM::TestNode, root.childs.first.class
    assert_equal "child", root.childs.first.text
  end

  def test_json_serializer_escapes
    testModel = TestMM::TestNode.new(:text => %Q(some " \\ \\" text \r xx \n xx \r\n xx \t xx \b xx \f))
    output = StringWriter.new
    ser = RGen::Serializer::JsonSerializer.new(output)

    assert_equal %q({ "_class": "TestNode", "text": "some \" \\\\ \\\\\" text \r xx \n xx \r\n xx \t xx \b xx \f" }),
      ser.serialize(testModel) 
  end
   
  def test_json_instantiator_escapes
    env = RGen::Environment.new
    inst = RGen::Instantiator::JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "text": "some \" \\\\ \\\\\" text \r xx \n xx \r\n xx \t xx \b xx \f" }))
    assert_equal %Q(some " \\ \\" text \r xx \n xx \r\n xx \t xx \b xx \f), env.elements.first.text
  end

  def test_json_instantiator_escape_single_backslash
    env = RGen::Environment.new
    inst = RGen::Instantiator::JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "text": "a single \\ will be just itself" }))
    assert_equal %q(a single \\ will be just itself), env.elements.first.text
  end

  def test_json_serializer_integer
    testModel = TestMM::TestNode.new(:integer => 7)
    output = StringWriter.new
    ser = RGen::Serializer::JsonSerializer.new(output)
    assert_equal %q({ "_class": "TestNode", "integer": 7 }), ser.serialize(testModel) 
  end

  def test_json_instantiator_integer
    env = RGen::Environment.new
    inst = RGen::Instantiator::JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "integer": 7 }))
    assert_equal 7, env.elements.first.integer
  end

  def test_json_serializer_float
    testModel = TestMM::TestNode.new(:float => 1.23)
    output = StringWriter.new
    ser = RGen::Serializer::JsonSerializer.new(output)
    assert_equal %q({ "_class": "TestNode", "float": 1.23 }), ser.serialize(testModel) 
  end

  def test_json_instantiator_float
    env = RGen::Environment.new
    inst = RGen::Instantiator::JsonInstantiator.new(env, TestMM)
    inst.instantiate(%q({ "_class": "TestNode", "float": 1.23 }))
    assert_equal 1.23, env.elements.first.float
  end
end
	
