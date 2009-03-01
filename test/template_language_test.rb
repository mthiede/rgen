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
    File.open(OUTPUT_DIR+"/expected_result1.txt") {|f| expected = f.read}
    assert_equal expected, result
  end
  
  def test_immediate_result
    tc = RGen::TemplateLanguage::DirectoryTemplateContainer.new([MyMM, CCodeMM], OUTPUT_DIR)
    tc.load(TEMPLATES_DIR)
    expected = ""
    File.open(OUTPUT_DIR+"/expected_result2.txt") {|f| expected = f.read}
    assert_equal expected, tc.expand('code/array::ArrayDefinition', :for => TEST_MODEL.sampleArray).to_s
  end
  
  def test_indent_string
    tc = RGen::TemplateLanguage::DirectoryTemplateContainer.new([MyMM, CCodeMM], OUTPUT_DIR)
    tc.load(TEMPLATES_DIR)
    tc.indentString = "  "  # 2 spaces instead of 3 (default)
    tc.expand('indent_string_test::IndentStringTest', :for => :dummy)
    File.open(OUTPUT_DIR+"/indentStringTestDefaultIndent.out","rb") do |f|
      assert_equal "  <- your default here\r\n", f.read
    end
    File.open(OUTPUT_DIR+"/indentStringTestTabIndent.out","rb") do |f|
      assert_equal "\t<- tab\r\n", f.read
    end
  end
  
  def test_null_context
    tc = RGen::TemplateLanguage::DirectoryTemplateContainer.new([MyMM, CCodeMM], OUTPUT_DIR)
    tc.load(TEMPLATES_DIR)
    assert_raise StandardError do 
      # the template must raise an exception because it calls expand :for => nil
      tc.expand('null_context_test::NullContextTestBad', :for => :dummy)
    end
    assert_raise StandardError do 
      # the template must raise an exception because it calls expand :foreach => nil
      tc.expand('null_context_test::NullContextTestBad2', :for => :dummy)
    end
    assert_nothing_raised do
      tc.expand('null_context_test::NullContextTestOk', :for => :dummy)
    end
  end
end
