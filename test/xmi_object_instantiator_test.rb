$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'ea/xmi_object_instantiator'

class XmiObjectInstantiatorTest < Test::Unit::TestCase

	MODEL_DIR = File.join(File.dirname(__FILE__),"xmi_instantiator_test")

	include UMLObjectModel

	def test_model
		envUML = RGen::Environment.new
		File.open(MODEL_DIR+"/testmodel.xml") { |f|
			XMIObjectInstantiator.new.instantiateUMLObjectModel(envUML, f.read)
		}
		
		# check main package
		mainPackage = envUML.elements.select {|e| e.is_a? UMLPackage and e.name == "HouseExampleModel"}.first
		assert_not_nil mainPackage
		
		# check main package objects
		assert mainPackage.objects.is_a?(Array)
		assert_equal 6, mainPackage.objects.size
		assert mainPackage.objects.all?{|o| o.is_a?(UMLObject)}

		someone = mainPackage.objects.select{|o| o.name == "Someone"}.first
		assert_equal "Person", someone.classname
		
		someonesHouse = mainPackage.objects.select{|o| o.name == "SomeonesHouse"}.first
		assert_equal "House", someonesHouse.classname

		greenRoom = mainPackage.objects.select{|o| o.name == "GreenRoom"}.first
		assert_equal "Room", greenRoom.classname

		yellowRoom = mainPackage.objects.select{|o| o.name == "YellowRoom"}.first
		assert_equal "Room", yellowRoom.classname

		hotRoom = mainPackage.objects.select{|o| o.name == "HotRoom"}.first
		assert_equal "Kitchen", hotRoom.classname

		wetRoom = mainPackage.objects.select{|o| o.name == "WetRoom"}.first
		assert_equal "Bathroom", wetRoom.classname
		
		# Someone to SomeonesHouse
		assert someone.assocEnds.otherEnd.object.is_a?(Array)
		assert_equal 1, someone.assocEnds.otherEnd.object.size
		houseEnd = someone.assocEnds.otherEnd[0]
		assert_equal someonesHouse.object_id, houseEnd.object.object_id
		assert_equal "home", houseEnd.role
		
		# Someone to SomeonesHouse
		assert someonesHouse.localCompositeEnds.otherEnd.is_a?(Array)
		assert_equal 4, someonesHouse.localCompositeEnds.otherEnd.size
		assert someonesHouse.localCompositeEnds.otherEnd.all?{|e| e.role == "room"}
		assert_not_nil someonesHouse.localCompositeEnds.otherEnd.object.select{|o| o == yellowRoom}.first
		assert_not_nil someonesHouse.localCompositeEnds.otherEnd.object.select{|o| o == greenRoom}.first
		assert_not_nil someonesHouse.localCompositeEnds.otherEnd.object.select{|o| o == hotRoom}.first
		assert_not_nil someonesHouse.localCompositeEnds.otherEnd.object.select{|o| o == wetRoom}.first

		# check overall number of UMLObject objects
		assert_equal 6, envUML.elements.select{|e| e.is_a? UMLObject}.size
		
	end
end