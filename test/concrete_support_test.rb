$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/environment'
require 'concrete_support/concrete_mmm'
require 'concrete_support/ecore_to_concrete'
require 'concrete_support/json_serializer'

class ConcreteSupportTest < Test::Unit::TestCase
  include ConcreteSupport

  def test_ecore_to_concrete
    env = RGen::Environment.new
    outfile = File.dirname(__FILE__)+"/concrete_support_test/concrete_mmm_generated.js"
    ECoreToConcrete.new(nil, env).trans(ConcreteMMM.ecore.eClasses)
    File.open(outfile, "w") do |f|
      ser = JsonSerializer.new(f)
      ser.serialize(env.find(:class => ConcreteMMM::Class))        
    end
  end
end
	
