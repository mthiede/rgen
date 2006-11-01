$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/xml_instantiator'
require 'rgen/environment'
require 'rgen/model_dumper'

module EmptyMM
end

module DefaultMM
	module MNS
		class Room < RGen::MetamodelBuilder::MMBase; end
	end
	class Person < RGen::MetamodelBuilder::MMBase; end
	Person.one_to_one 'personalRoom', MNS::Room, 'inhabitant'
end

class XMLInstantiatorTest < Test::Unit::TestCase

	XML_DIR = File.join(File.dirname(__FILE__),"xml_instantiator_test")
	
	include RGen::ModelDumper
	
	class MyInstantiator < RGen::XMLInstantiator
	
		map_tag_ns "testmodel.org/myNamespace", DefaultMM::MNS
		
#		resolve :type do
#			@env.find(:xmi_id => getType).first
#		end
	
		resolve_by_id :personalRoom, :id => :getId, :src => :room
		
	end
	
	def test_custom
		env = RGen::Environment.new
		inst = MyInstantiator.new(env, DefaultMM, true)
		inst.instantiate_file(File.join(XML_DIR,"testmodel.xml"))
		
		house = env.find(:class => DefaultMM::MNS::House).first
		assert_not_nil house
		assert_equal 2, house.room.size
		
		rooms = env.find(:class => DefaultMM::MNS::Room)
		assert_equal 2, rooms.size
		assert_equal 0, (house.room - rooms).size
		rooms.each {|r| assert r.parent == house}
		tomsRoom = rooms.select{|r| r.name == "TomsRoom"}.first
		assert_not_nil tomsRoom
		
		persons = env.find(:class => DefaultMM::Person)
		assert_equal 1, persons.size
		tom = persons.select{|p| p.name == "Tom"}.first
		assert_not_nil tom
		
		assert tom.personalRoom == tomsRoom
	end
	
	def test_default
		env = RGen::Environment.new
		inst = RGen::XMLInstantiator.new(env, EmptyMM, true)
		inst.instantiate_file(File.join(XML_DIR,"testmodel.xml"))
		
		house = env.find(:class => EmptyMM::MNS_House).first
		assert_not_nil house
		assert_equal 2, house.mNS_Room.size
		
		rooms = env.find(:class => EmptyMM::MNS_Room)
		assert_equal 2, rooms.size
		assert_equal 0, (house.mNS_Room - rooms).size
		rooms.each {|r| assert r.parent == house}
		tomsRoom = rooms.select{|r| r.name == "TomsRoom"}.first
		assert_not_nil tomsRoom
		
		persons = env.find(:class => EmptyMM::Person)
		assert_equal 1, persons.size
		tom = persons.select{|p| p.name == "Tom"}.first
		assert_not_nil tom
	end
	
end