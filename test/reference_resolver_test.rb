$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'
require 'rgen/instantiator/reference_resolver'

class ReferenceResolverTest < Test::Unit::TestCase

  class TestNode < RGen::MetamodelBuilder::MMBase
    has_attr 'name', String
    has_one 'other', TestNode
    has_many 'others', TestNode
  end

  class TestResolver
    include RGen::Instantiator::ReferenceResolver
    def initialize(nodeA, nodeB, nodeC)
      @nodeA, @nodeB, @nodeC = nodeA, nodeB, nodeC
    end
    def resolveIdentifier(ident)
      {:a => @nodeA, :b => @nodeB, :c => @nodeC}[ident] 
    end
  end

  def test_simple
    nodeA = TestNode.new(:name => "NodeA")
    nodeB = TestNode.new(:name => "NodeB")
    nodeC = TestNode.new(:name => "NodeC")
    bProxy = RGen::MetamodelBuilder::MMProxy.new(:b) 
    nodeA.other = bProxy 
    aProxy = RGen::MetamodelBuilder::MMProxy.new(:a) 
    cProxy = RGen::MetamodelBuilder::MMProxy.new(:c) 
    nodeB.others = [aProxy, cProxy] 
    unresolvedReferences = [
      RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(nodeA, "other", bProxy),
      RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(nodeB, "others", aProxy),
      RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(nodeB, "others", cProxy)
    ]
    resolver = TestResolver.new(nodeA, nodeB, nodeC)
    resolver.resolveReferences(unresolvedReferences)
    assert_equal nodeB, nodeA.other
    assert_equal [], nodeA.others
    assert_equal nil, nodeB.other
    assert_equal [nodeA, nodeC], nodeB.others
    assert_equal nil, nodeC.other
    assert_equal [], nodeC.others
  end

end
 
