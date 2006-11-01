$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/template_language'

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
		attr_reader :title, :author, :chapters
		def initialize(title, author)
			@title, @author = title, author
			@chapters = []
		end
	end
	
	end
	
	TEST_MODEL = MyMM::Document.new("SomeDocument","MyName")
	TEST_MODEL.chapters << MyMM::Chapter.new("Intro")
	TEST_MODEL.chapters << MyMM::Chapter.new("MainPart")
	TEST_MODEL.chapters << MyMM::Chapter.new("Summary")
	
	def test_with_model
		tc = RGen::TemplateLanguage::DirectoryTemplateContainer.new(MyMM, OUTPUT_DIR)
		tc.load(TEMPLATES_DIR)
		File.delete(OUTPUT_DIR+"/testout.txt") if File.exists? OUTPUT_DIR+"/testout.txt"
		tc.expand('root::Root', :for => TEST_MODEL, :indent => 1)
		result = expected = ""
		File.open(OUTPUT_DIR+"/testout.txt") {|f| result = f.read}
		File.open(OUTPUT_DIR+"/expected_result.txt") {|f| expected = f.read}
		assert_equal expected, result
	end
	
end
