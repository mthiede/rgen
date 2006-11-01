$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'

class MetamodelBuilderTest < Test::Unit::TestCase

	class HasOneTestClass < RGen::MetamodelBuilder::MMBase
		has_one 'name'
		has_one 'an_array', Array
	end
	
	def test_has_one
		sc = HasOneTestClass.new
		assert_respond_to sc, :name
		assert_respond_to sc, :name=
		sc.name = 'SomeName'
		assert_equal 'SomeName', sc.name
		sc.name = nil
		assert_equal nil, sc.name

		assert_respond_to sc, :an_array
		assert_respond_to sc, :an_array=
		aa = Array.new
		sc.an_array = aa
		assert_equal aa, sc.an_array
		
		assert_raise StandardError do
			sc.an_array = "a string"
		end
		
		assert_equal HasOneTestClass.one_attributes, ["name", "an_array"]
		assert_equal HasOneTestClass.many_attributes, []
	end
	
	class HasManyTestClass < RGen::MetamodelBuilder::MMBase
		has_many 'string', String
	end
	
	def test_has_many
		o = HasManyTestClass.new
		o.addString("s1")
		o.addString("s2")
		assert_equal ["s1","s2"], o.string
		# make sure we get a copy
		o.string.clear
		assert_equal ["s1","s2"], o.string
		o.removeString("s3")
		assert_equal ["s1","s2"], o.string
		o.removeString("s2")
		assert_equal ["s1"], o.string
		assert_raise StandardError do
			o.addString(:notastring)
		end
		assert_equal HasManyTestClass.one_attributes, []
		assert_equal HasManyTestClass.many_attributes, ["string"]
	end

	class OneClass < RGen::MetamodelBuilder::MMBase
	end
	class ManyClass < RGen::MetamodelBuilder::MMBase
	end
	OneClass.one_to_many 'manyClasses', ManyClass, 'oneClass'
	
	def test_one_to_many
		oc = OneClass.new
		assert_respond_to oc, :manyClasses
		assert oc.manyClasses.empty?
		
		mc = ManyClass.new
		assert_respond_to mc, :oneClass
		assert_respond_to mc, :oneClass=
		assert_nil mc.oneClass
		
		# put the OneClass into the ManyClass
		mc.oneClass = oc
		assert_equal oc, mc.oneClass
		assert oc.manyClasses.include?(mc)
		
		# remove the OneClass from the ManyClass
		mc.oneClass = nil
		assert_equal nil, mc.oneClass
		assert !oc.manyClasses.include?(mc)

		# put the ManyClass into the OneClass
		oc.addManyClasses mc
		assert oc.manyClasses.include?(mc)
		assert_equal oc, mc.oneClass
		
		# remove the ManyClass from the OneClass
		oc.removeManyClasses mc
		assert !oc.manyClasses.include?(mc)
		assert_equal nil, mc.oneClass

		assert_equal OneClass.one_attributes, []
		assert_equal OneClass.many_attributes, ["manyClasses"]
		assert_equal ManyClass.one_attributes, ["oneClass"]
		assert_equal ManyClass.many_attributes, []
	end

	class OneClass2 < RGen::MetamodelBuilder::MMBase
	end
	class ManyClass2 < RGen::MetamodelBuilder::MMBase
	end
	ManyClass2.many_to_one 'oneClass', OneClass2, 'manyClasses'
	
	def test_one_to_many2
		oc = OneClass2.new
		assert_respond_to oc, :manyClasses
		assert oc.manyClasses.empty?
		
		mc = ManyClass2.new
		assert_respond_to mc, :oneClass
		assert_respond_to mc, :oneClass=
		assert_nil mc.oneClass
		
		# put the OneClass into the ManyClass
		mc.oneClass = oc
		assert_equal oc, mc.oneClass
		assert oc.manyClasses.include?(mc)
		
		# remove the OneClass from the ManyClass
		mc.oneClass = nil
		assert_equal nil, mc.oneClass
		assert !oc.manyClasses.include?(mc)

		# put the ManyClass into the OneClass
		oc.addManyClasses mc
		assert oc.manyClasses.include?(mc)
		assert_equal oc, mc.oneClass
		
		# remove the ManyClass from the OneClass
		oc.removeManyClasses mc
		assert !oc.manyClasses.include?(mc)
		assert_equal nil, mc.oneClass

		assert_equal OneClass2.one_attributes, []
		assert_equal OneClass2.many_attributes, ["manyClasses"]
		assert_equal ManyClass2.one_attributes, ["oneClass"]
		assert_equal ManyClass2.many_attributes, []
	end

	class AClassOO < RGen::MetamodelBuilder::MMBase
	end
	class BClassOO < RGen::MetamodelBuilder::MMBase
	end
	AClassOO.one_to_one 'bClass', BClassOO, 'aClass'

	def test_one_to_one
		ac = AClassOO.new
		assert_respond_to ac, :bClass
		assert_respond_to ac, :bClass=
		assert_nil ac.bClass
		
		bc = BClassOO.new
		assert_respond_to bc, :aClass
		assert_respond_to bc, :aClass=
		assert_nil bc.aClass
		
		# put the AClass into the BClass
		bc.aClass = ac
		assert_equal ac, bc.aClass
		assert_equal bc, ac.bClass
		
		# remove the AClass from the BClass
		bc.aClass = nil
		assert_equal nil, bc.aClass
		assert_equal nil, ac.bClass

		# put the BClass into the AClass
		ac.bClass = bc
		assert_equal bc, ac.bClass
		assert_equal ac, bc.aClass
		
		# remove the BClass from the AClass
		ac.bClass = nil
		assert_equal nil, ac.bClass
		assert_equal nil, bc.aClass

		assert_equal AClassOO.one_attributes, ["bClass"]
		assert_equal AClassOO.many_attributes, []
		assert_equal BClassOO.one_attributes, ["aClass"]
		assert_equal BClassOO.many_attributes, []
	end

	class AClassMM < RGen::MetamodelBuilder::MMBase
	end
	class BClassMM < RGen::MetamodelBuilder::MMBase
	end
	AClassMM.many_to_many 'bClasses', BClassMM, 'aClasses'

	def test_many_to_many
	
		ac = AClassMM.new
		assert_respond_to ac, :bClasses
		assert ac.bClasses.empty?

		bc = BClassMM.new
		assert_respond_to bc, :aClasses
		assert bc.aClasses.empty?
		
		# put the AClass into the BClass
		bc.addAClasses ac
		assert bc.aClasses.include?(ac)
		assert ac.bClasses.include?(bc)
		
		# put something else into the BClass
		assert_raise StandardError do
			bc.addAClasses :notaaclass
		end
		
		# remove the AClass from the BClass
		bc.removeAClasses ac
		assert !bc.aClasses.include?(ac)
		assert !ac.bClasses.include?(bc)

		# put the BClass into the AClass
		ac.addBClasses bc
		assert ac.bClasses.include?(bc)
		assert bc.aClasses.include?(ac)
		
		# put something else into the AClass
		assert_raise StandardError do
			ac.addBClasses :notabclass
		end
		
		# remove the BClass from the AClass
		ac.removeBClasses bc
		assert !ac.bClasses.include?(bc)
		assert !bc.aClasses.include?(ac)

		assert_equal AClassMM.one_attributes, []
		assert_equal AClassMM.many_attributes, ["bClasses"]
		assert_equal BClassMM.one_attributes, []
		assert_equal BClassMM.many_attributes, ["aClasses"]
	end
	
	class SomeSuperClass < RGen::MetamodelBuilder::MMBase
		has_one "name"
		has_many "others"
	end
	
	class SomeSubClass < SomeSuperClass
		has_one "subname"
		has_many "subothers"
	end
	
	class OtherSubClass < SomeSuperClass
		has_one "othersubname"
		has_many "othersubothers"
	end
	
	def test_inheritance
		assert_equal SomeSuperClass.one_attributes, ["name"]
		assert_equal SomeSuperClass.many_attributes, ["others"]
		assert_equal SomeSubClass.one_attributes.sort, ["name", "subname"]
		assert_equal SomeSubClass.many_attributes.sort, ["others", "subothers"]
		assert_equal OtherSubClass.one_attributes.sort, ["name", "othersubname"]
		assert_equal OtherSubClass.many_attributes.sort, ["others", "othersubothers"]
	end
end
