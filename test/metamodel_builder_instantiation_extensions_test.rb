$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'

class MetamodelBuilderInstantiationExtensionsTest < Test::Unit::TestCase
  
  module TestMetamodel

    class StringLiteral < RGen::MetamodelBuilder::MMBase
      has_attr 'value', String
    end

    class IntegerLiteral < RGen::MetamodelBuilder::MMBase
      has_attr 'n', Integer
    end    

    class << StringLiteral
      include RGen::MetamodelBuilder::InstantiationExtensions
    end

    class << IntegerLiteral
      include RGen::MetamodelBuilder::InstantiationExtensions
    end

  end

  def test_build_from_value
    s = TestMetamodel::StringLiteral.build_from_value('hello string!')
    assert s.is_a?(TestMetamodel::StringLiteral), "Expected to be a StringLiteral but it is #{s.class}"
    assert_equal 'hello string!',s.value

    i = TestMetamodel::IntegerLiteral.build_from_value(12)
    assert i.is_a?(TestMetamodel::IntegerLiteral), "Expected to be a InteLgeriteral but it is #{i.class}"
    assert_equal 12,i.n    
  end

end
