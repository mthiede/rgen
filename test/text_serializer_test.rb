$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'
require 'rgen/metamodel_builder'
require 'rgen/serializer/text_serializer'

class TextTest < Test::Unit::TestCase

  class StringWriter < String
    alias write concat
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

  def test_simple
    testModel = TestMM::TestNode.new(:text => "some text", :childs => [
      TestMM::TestNode.new(:text => "child")])

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new.serialize(testModel, output)

    assert_equal %Q(\
TestNode text: "some text" {
  TestNode text: "child"
}
), output 
  end

  module TestMMFeatureProvider
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'attr1', String
      has_attr 'attr2', String
      has_attr 'attr3', String
      contains_many 'childs1', TestNode, 'parent1'
      contains_many 'childs2', TestNode, 'parent2'
      contains_many 'childs3', TestNode, 'parent3'
    end
  end

  def test_feature_provider
    testModel = TestMMFeatureProvider::TestNode.new(
      :attr1 => "attr1",
      :attr2 => "attr2",
      :attr3 => "attr3",
      :childs1 => [TestMMFeatureProvider::TestNode.new(:attr1 => "child1")],
      :childs2 => [TestMMFeatureProvider::TestNode.new(:attr1 => "child2")],
      :childs3 => [TestMMFeatureProvider::TestNode.new(:attr1 => "child3")])

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new(
      :feature_provider => proc {|clazz| 
        clazz.eAllStructuralFeatures.reject{|f| f.name =~ /parent|2$/}.reverse}
    ).serialize(testModel, output)

    assert_equal %Q(\
TestNode attr3: "attr3", attr1: "attr1" {
  childs3:
    TestNode attr1: "child3"
  childs1:
    TestNode attr1: "child1"
}
), output 
  end

  module TestMMUnlabledUnquoted
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'unlabled', String
      has_attr 'unquoted', String
      has_attr 'both', String
      has_attr 'none', String
    end
  end

  def test_unlabled_unquoted
    testModel = TestMMUnlabledUnquoted::TestNode.new(:unlabled => "unlabled", :unquoted => "unquoted", :both => "both", :none => "none")

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new(
      :unlabled_arguments => proc {|clazz| clazz.eAttributes.select{|a| a.name == "unlabled" || a.name == "both"}},
      :unquoted_arguments => proc {|clazz| clazz.eAttributes.select{|a| a.name == "unquoted" || a.name == "both"}}
    ).serialize(testModel, output)

    assert_equal %Q(\
TestNode "unlabled", both, unquoted: unquoted, none: "none"
), output 
  end
  
  module TestMMComment
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'comment', String
      contains_many 'childs', TestNode, 'parent'
    end
  end

  def test_comment_provider
    testModel = TestMMComment::TestNode.new(
      :comment => "this is a comment",
      :childs => [TestMMComment::TestNode.new(
        :comment => "comment of a child node\n  multiline")])

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new(
      :comment_provider => proc { |e| 
        c = e.comment
        e.comment = nil
        c
      }).serialize(testModel, output)

    assert_equal %Q(\
#this is a comment
TestNode {
  #comment of a child node
  #  multiline
  TestNode
}
), output 
  end

  def test_indent_string
    testModel = TestMM::TestNode.new(:childs => [
      TestMM::TestNode.new(:text => "child")])

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new(:indent_string => "____").serialize(testModel, output)

    assert_equal %Q(\
TestNode {
____TestNode text: "child"
}
), output 
  end

  module TestMMRef
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'name', String
      contains_many 'childs', TestNode, 'parent'
      has_many 'refMany', TestNode
      has_one 'refOne', TestNode
      one_to_many 'refManyBi', TestNode, 'refManyBack'
      one_to_one 'refOneBi', TestNode, 'refOneBack'
      many_to_many 'refManyMany', TestNode, 'refManyManyBack'
    end
  end

  def test_identifier_provider
    testModel = [
      TestMMRef::TestNode.new(:name => "Source"),
      TestMMRef::TestNode.new(:name => "Target")]
    testModel[0].refOne = testModel[1]

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new(
      :identifier_provider => proc{|e, context| 
        assert_equal testModel[0], context
        "/target/ref"
      }
    ).serialize(testModel, output) 

    assert_equal %Q(\
TestNode name: "Source", refOne: /target/ref
TestNode name: "Target"
),output
  end

  def test_references
    testModel = [ 
      TestMMRef::TestNode.new(:name => "Source"),
      TestMMRef::TestNode.new(:name => "Target",
        :childs => [
          TestMMRef::TestNode.new(:name => "A",
          :childs => [
            TestMMRef::TestNode.new(:name => "A1")
          ]),
          TestMMRef::TestNode.new(:name => "B"),
        ])
    ]
    testModel[0].refOne = testModel[1].childs[0].childs[0]
    testModel[0].refOneBi = testModel[1].childs[0].childs[0]
    testModel[0].refMany = [testModel[1].childs[0], testModel[1].childs[1]]
    testModel[0].refManyBi = [testModel[1].childs[0], testModel[1].childs[1]]
    testModel[0].refManyMany = [testModel[1].childs[0], testModel[1].childs[1]]
    testModel[0].addRefMany(RGen::MetamodelBuilder::MMProxy.new("/some/ref"))

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new.serialize(testModel, output)

    assert_equal %Q(\
TestNode name: "Source", refMany: [/Target/A, /Target/B, /some/ref], refOne: /Target/A/A1, refOneBi: /Target/A/A1
TestNode name: "Target" {
  TestNode name: "A", refManyBack: /Source, refManyManyBack: /Source {
    TestNode name: "A1"
  }
  TestNode name: "B", refManyBack: /Source, refManyManyBack: /Source
}
), output
  end

  module TestMMChildRole
    extend RGen::MetamodelBuilder::ModuleExtension
    class TestNodeA < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
    end
    class TestNodeB < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
    end
    class TestNodeC < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
    end
    class TestNodeD < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
    end
    class TestNodeE < RGen::MetamodelBuilder::MMMultiple(TestNodeC, TestNodeD)
      has_attr 'text', String
    end
    class TestNode < RGen::MetamodelBuilder::MMBase
      has_attr 'text', String
      contains_one 'child1', TestNode, 'parent1'
      contains_many 'childs2', TestNode, 'parent2'
      contains_one 'child3', TestNodeA, 'parent3'
      contains_many 'childs4', TestNodeB, 'parent4'
      contains_one 'child5', TestNodeC, 'parent5'
      contains_many 'childs6', TestNodeD, 'parent6'
    end
  end

  def test_child_role
    testModel = TestMMChildRole::TestNode.new(
      :child1 => TestMMChildRole::TestNode.new(:text => "child1"),
      :childs2 => [
        TestMMChildRole::TestNode.new(:text => "child2a"),
        TestMMChildRole::TestNode.new(:text => "child2b")
      ],
      :child3 => TestMMChildRole::TestNodeA.new(:text => "child3"),
      :childs4 => [TestMMChildRole::TestNodeB.new(:text => "child4")],
      :child5 => TestMMChildRole::TestNodeC.new(:text => "child5"),
      :childs6 => [TestMMChildRole::TestNodeD.new(:text => "child6")]
      )

    output = StringWriter.new
    RGen::Serializer::TextSerializer.new.serialize(testModel, output)

    assert_equal %Q(\
TestNode {
  child1:
    TestNode text: "child1"
  childs2: [
    TestNode text: "child2a"
    TestNode text: "child2b"
  ]
  TestNodeA text: "child3"
  TestNodeB text: "child4"
  child5:
    TestNodeC text: "child5"
  childs6:
    TestNodeD text: "child6"
}
), output 
  end

  def test_escapes
    testModel = TestMM::TestNode.new(:text => %Q(some " \\ \\" text \r xx \n xx \r\n xx \t xx \b xx \f))
    output = StringWriter.new
    RGen::Serializer::TextSerializer.new.serialize(testModel, output) 

    assert_equal %q(TestNode text: "some \" \\\\ \\\\\" text \r xx \n xx \r\n xx \t xx \b xx \f")+"\n", output
  end

  def test_integer
    testModel = TestMM::TestNode.new(:integer => 7)
    output = StringWriter.new
    RGen::Serializer::TextSerializer.new.serialize(testModel, output) 
    assert_equal %q(TestNode integer: 7)+"\n", output
  end

  def test_float
    testModel = TestMM::TestNode.new(:float => 1.23)
    output = StringWriter.new
    RGen::Serializer::TextSerializer.new.serialize(testModel, output) 
    assert_equal %q(TestNode float: 1.23)+"\n", output 
  end

  module TestMMData
    extend RGen::MetamodelBuilder::ModuleExtension
    # class "Data" exists in the standard Ruby namespace
    class Data < RGen::MetamodelBuilder::MMBase
      has_attr 'notTheBuiltin', String
    end
  end

  module TestMMSubpackage
    extend RGen::MetamodelBuilder::ModuleExtension
    module SubPackage
      extend RGen::MetamodelBuilder::ModuleExtension
      class Data < RGen::MetamodelBuilder::MMBase
        has_attr 'notTheBuiltin', String
      end
      class Data2 < RGen::MetamodelBuilder::MMBase
        has_attr 'data2', String
      end
    end
  end

  def test_subpackage
    testModel = TestMMSubpackage::SubPackage::Data2.new(:data2 => "xxx")
    output = StringWriter.new
    RGen::Serializer::TextSerializer.new.serialize(testModel, output) 
    assert_equal %q(Data2 data2: "xxx")+"\n", output
  end

end

