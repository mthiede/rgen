$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/template_language'
require 'rgen/metamodel_builder'

class TemplateContainerTest < Test::Unit::TestCase
  
  TEMPLATES_DIR = File.dirname(__FILE__)+"/template_language_test/templates"
  OUTPUT_DIR = File.dirname(__FILE__)+"/template_language_test"
  
  module MyMM
    
    class Chapter
      attr_reader :title
      def initialize(title)
        @title = title
      end
    end
    
    class Document
      attr_reader :title, :authors, :chapters
      attr_accessor :sampleArray
      def initialize(title)
        @title = title
        @chapters = []
        @authors = []
      end
    end
    
    class Author
      attr_reader :name, :email
      def initialize(name, email)
        @name, @email = name, email
      end      
    end
    
  end
  
  module CCodeMM
    class CArray < RGen::MetamodelBuilder::MMBase
      has_attr 'name'
      has_attr 'size', Integer
      has_attr 'type'
    end
    class PrimitiveInitValue < RGen::MetamodelBuilder::MMBase
      has_attr 'value', Integer
    end
    CArray.has_many 'initvalue', PrimitiveInitValue
  end
  
  TEST_MODEL = MyMM::Document.new("SomeDocument")
  TEST_MODEL.authors << MyMM::Author.new("Martin", "martin@somewhe.re")
  TEST_MODEL.authors << MyMM::Author.new("Otherguy", "other@somewhereel.se")
  TEST_MODEL.chapters << MyMM::Chapter.new("Intro")
  TEST_MODEL.chapters << MyMM::Chapter.new("MainPart")
  TEST_MODEL.chapters << MyMM::Chapter.new("Summary")
  TEST_MODEL.sampleArray = CCodeMM::CArray.new(:name => "myArray", :type => "int", :size => 5,
    :initvalue => (1..5).collect { |v| CCodeMM::PrimitiveInitValue.new(:value => v) })
  
  def test_with_model
    tc = RGen::TemplateLanguage::DirectoryTemplateContainer.new([MyMM, CCodeMM], OUTPUT_DIR)
    tc.load(TEMPLATES_DIR)
    File.delete(OUTPUT_DIR+"/testout.txt") if File.exists? OUTPUT_DIR+"/testout.txt"
    tc.expand('root::Root', :for => TEST_MODEL, :indent => 1)
    result = expected = ""
    File.open(OUTPUT_DIR+"/testout.txt") {|f| result = f.read}
    File.open(OUTPUT_DIR+"/expected_result.txt") {|f| expected = f.read}
    assert_equal expected, result
  end
  
end
