require 'uml/uml_classmodel'

module ClassModelChecker			
	include UMLClassModel

	def checkClassModel(envUML)
						
		# check main package
		mainPackage = envUML.elements.select {|e| e.is_a? UMLPackage and e.name == "HouseMetamodel"}.first
		assert_not_nil mainPackage
		
		# check Rooms package
		assert mainPackage.subpackages.is_a?(Array)
		assert_equal 1, mainPackage.subpackages.size
		assert mainPackage.subpackages[0].is_a?(UMLPackage)
		roomsPackage = mainPackage.subpackages[0]
		assert_equal "Rooms", roomsPackage.name
		
		# check main package classes
		assert mainPackage.classes.is_a?(Array)
		assert_equal 3, mainPackage.classes.size
		assert mainPackage.classes.all?{|c| c.is_a?(UMLClass)}
		houseClass = mainPackage.classes.select{|c| c.name == "House"}.first
		personClass = mainPackage.classes.select{|c| c.name == "Person"}.first
		meetingPlaceClass = mainPackage.classes.select{|c| c.name == "MeetingPlace"}.first
		assert_not_nil houseClass
		assert_not_nil personClass
		assert_not_nil meetingPlaceClass

		# check Rooms package classes
		assert roomsPackage.classes.is_a?(Array)
		assert_equal 3, roomsPackage.classes.size
		assert roomsPackage.classes.all?{|c| c.is_a?(UMLClass)}
		roomClass = roomsPackage.classes.select{|c| c.name == "Room"}.first
		kitchenClass = roomsPackage.classes.select{|c| c.name == "Kitchen"}.first
		bathroomClass = roomsPackage.classes.select{|c| c.name == "Bathroom"}.first
		assert_not_nil roomClass
		assert_not_nil kitchenClass
		assert_not_nil bathroomClass
		
		# check Room inheritance
		assert roomClass.subclasses.is_a?(Array)
		assert_equal 2, roomClass.subclasses.size
		assert_not_nil roomClass.subclasses.select{|c| c.name == "Kitchen"}.first
		assert_not_nil roomClass.subclasses.select{|c| c.name == "Bathroom"}.first
		assert kitchenClass.superclasses.is_a?(Array)
		assert_equal 2, kitchenClass.superclasses.size
		assert_equal roomClass.object_id, kitchenClass.superclasses.select{|c| c.name == "Room"}.first.object_id
		assert_equal meetingPlaceClass.object_id, kitchenClass.superclasses.select{|c| c.name == "MeetingPlace"}.first.object_id
		assert bathroomClass.superclasses.is_a?(Array)
		assert_equal 1, bathroomClass.superclasses.size
		assert_equal roomClass.object_id, bathroomClass.superclasses[0].object_id

		# check House-Room "part of" association
		assert houseClass.localCompositeEnds.otherEnd.clazz.is_a?(Array)
		assert_equal 1, houseClass.localCompositeEnds.size
		roomEnd = houseClass.localCompositeEnds[0].otherEnd
		assert_equal UMLAggregation, roomEnd.assoc.class
		assert_equal roomClass.object_id, roomEnd.clazz.object_id
		assert_equal "room", roomEnd.role
		assert_equal "1..*", roomEnd.multiplicity
		assert_equal 1, roomEnd.lowerMult
		assert_equal :many, roomEnd.upperMult
		
		assert roomClass.remoteCompositeEnds.clazz.is_a?(Array)
		assert_equal 1, roomClass.remoteCompositeEnds.size
		assert_equal houseClass.object_id, roomClass.remoteCompositeEnds[0].clazz.object_id
		assert_equal "house", roomClass.remoteCompositeEnds[0].role
				
		# check House OUT associations
		assert houseClass.remoteNavigableEnds.is_a?(Array)
		assert_equal 2, houseClass.remoteNavigableEnds.size
		bathEnd = houseClass.remoteNavigableEnds.select{|e| e.role == "bathroom"}.first
		kitchenEnd = houseClass.remoteNavigableEnds.select{|e| e.role == "kitchen"}.first
		assert_not_nil bathEnd
		assert_not_nil kitchenEnd
		assert_equal UMLAssociation, bathEnd.assoc.class
		assert_equal UMLAssociation, kitchenEnd.assoc.class
		assert_equal "1", kitchenEnd.multiplicity
		assert_equal 1, kitchenEnd.lowerMult
		assert_equal 1, kitchenEnd.upperMult
		
		# check House IN associations
		assert houseClass.localNavigableEnds.is_a?(Array)
		assert_equal 3, houseClass.localNavigableEnds.size
		homeEnd = houseClass.localNavigableEnds.select{|e| e.role == "home"}.first
		assert_not_nil homeEnd
		assert_equal UMLAssociation, homeEnd.assoc.class
		assert_equal "0..*", homeEnd.multiplicity
		assert_equal 0, homeEnd.lowerMult
		assert_equal :many, homeEnd.upperMult
		
		# check House all associations
		assert houseClass.assocEnds.is_a?(Array)
		assert_equal 4, houseClass.assocEnds.size
	end
end