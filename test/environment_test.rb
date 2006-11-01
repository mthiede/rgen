$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'

class EnvironmentTest < Test::Unit::TestCase

	class Model
		attr_accessor :name
	end
	
	class ModelSub < Model
	end

	def test_find
		m1 = Model.new
		m1.name = "M1"
		m2 = ModelSub.new
		m2.name = "M2"
		m3 = "justAString"
		env_in = RGen::Environment.new << m1 << m2 << m3

		result = env_in.find(:class => Model, :name => "M1")
		assert result.is_a?(Array)
		assert_equal 1, result.size
		assert_equal m1, result.first

		result = env_in.find(:class => Model)
		assert result.is_a?(Array)
		assert_equal 2, result.size
		assert_equal m1, result[0]
		assert_equal m2, result[1]
		
		result = env_in.find(:name => "M2")
		assert result.is_a?(Array)
		assert_equal 1, result.size
		assert_equal m2, result[0]		
		
		result = env_in.find(:class => [Model, String])
		assert result.is_a?(Array)
		assert_equal 3, result.size
		assert_equal m1, result[0]
		assert_equal m2, result[1]
		assert_equal m3, result[2]
	end
	
end
