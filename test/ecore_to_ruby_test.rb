$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'minitest/autorun'
require 'rgen/environment'
require 'rgen/ecore/ecore'
require 'rgen/ecore/ecore_ext'
require 'rgen/ecore/ecore_to_ruby'

class ECoreToRubyTest < MiniTest::Test

module ContainerSimple
end

module ContainerUnder
end

def test_simple
  p1 = create_ecore

  mod = RGen::ECore::ECoreToRuby.new.create_module(p1)
  
  assert mod.const_defined?(:P11)
  assert mod::P11.const_defined?(:C1)

  # temporary path
  assert mod::P11::C1.to_s.start_with?("#")

  ContainerSimple.const_set("P1", mod)
  assert_equal "ECoreToRubyTest::ContainerSimple::P1::P11::C1", ContainerSimple::P1::P11::C1.name
end

def test_under
  p1 = create_ecore

  RGen::ECore::ECoreToRuby.new.create_module(p1, ContainerUnder)
  
  assert ContainerUnder.const_defined?(:P1)
  assert ContainerUnder::P1.const_defined?(:P11)
  assert ContainerUnder::P1::P11.const_defined?(:C1)

  assert_equal "ECoreToRubyTest::ContainerUnder::P1::P11::C1", ContainerUnder::P1::P11::C1.name
end

def test_under_temp_path
  p1 = create_ecore

  container = Module.new
  RGen::ECore::ECoreToRuby.new.create_module(p1, container)
  
  assert container.const_defined?(:P1)
  assert container::P1.const_defined?(:P11)
  assert container::P1::P11.const_defined?(:C1)

  # temporary path
  assert container::P1::P11::C1.to_s.start_with?("#")

  self.class.const_set("Container2", container)
  assert_equal "ECoreToRubyTest::Container2::P1::P11::C1", container::P1::P11::C1.to_s
end

def create_ecore
  p1 = RGen::ECore::EPackage.new(:name => "P1")
  p11 = RGen::ECore::EPackage.new(:name => "P11", :eSuperPackage => p1)
  p12 = RGen::ECore::EPackage.new(:name => "P12", :eSuperPackage => p1)
  c1 = RGen::ECore::EClass.new(:name => "C1", :ePackage => p11)
  c2 = RGen::ECore::EClass.new(:name => "C2", :ePackage => p12)
  c3 = RGen::ECore::EClass.new(:name => "C3", :eSuperTypes => [c1, c2], :ePackage => p11)
  p1
end

end


