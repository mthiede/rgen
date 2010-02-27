$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'
require 'rgen/array_extensions'

class MetamodelBuilderTest < Test::Unit::TestCase
  
  class SimpleClass < RGen::MetamodelBuilder::MMBase
    KindType = RGen::MetamodelBuilder::DataTypes::Enum.new([:simple, :extended])
    has_attr 'name' # default is String
    has_attr 'stringWithDefault', String, :defaultValueLiteral => "xtest"
    has_attr 'anything', Object
    has_attr 'allowed', RGen::MetamodelBuilder::DataTypes::Boolean
    has_attr 'kind', KindType
    has_attr 'kindWithDefault', KindType, :defaultValueLiteral => "extended"
  end
  
  def test_has_attr
    sc = SimpleClass.new
    
    assert_respond_to sc, :name
    assert_respond_to sc, :name=
    sc.name = "TestName"
    assert_equal "TestName", sc.name
    sc.name = nil
    assert_equal nil, sc.name
    assert_raise StandardError do
      sc.name = 5
    end
    assert_equal "EString", SimpleClass.ecore.eAttributes.find{|a| a.name=="name"}.eType.name

    assert_equal "xtest", sc.stringWithDefault
    assert_equal :extended, sc.kindWithDefault
    
    sc.anything = :asymbol
    assert_equal :asymbol, sc.anything
    sc.anything = self # a class
    assert_equal self, sc.anything
    
    assert_respond_to sc, :allowed
    assert_respond_to sc, :allowed=
    sc.allowed = true
    assert_equal true, sc.allowed
    sc.allowed = false
    assert_equal false, sc.allowed
    sc.allowed = nil
    assert_equal nil, sc.allowed
    assert_raise StandardError do
      sc.allowed = :someSymbol
    end
    assert_raise StandardError do
      sc.allowed = "a string"
    end
    assert_equal "EBoolean", SimpleClass.ecore.eAttributes.find{|a| a.name=="allowed"}.eType.name
    
    assert_respond_to sc, :kind
    assert_respond_to sc, :kind=
    sc.kind = :simple
    assert_equal :simple, sc.kind
    sc.kind = :extended
    assert_equal :extended, sc.kind
    sc.kind = nil
    assert_equal nil, sc.kind
    assert_raise StandardError do
      sc.kind = :false
    end
    assert_raise StandardError do
      sc.kind = "a string"
    end
    
    enum = SimpleClass.ecore.eAttributes.find{|a| a.name=="kind"}.eType
    assert_equal ["extended", "simple"], enum.eLiterals.name.sort
  end
  
  class ManyAttrClass < RGen::MetamodelBuilder::MMBase
    has_many_attr 'literals', String
    has_many_attr 'bools', Boolean
    has_many_attr 'integers', Integer
    has_many_attr 'enums', RGen::MetamodelBuilder::DataTypes::Enum.new([:a, :b, :c])
    has_many_attr 'limitTest', Integer, :upperBound => 2
  end

  def test_many_attr
    o = ManyAttrClass.new

    assert_respond_to o, :literals
    assert_respond_to o, :addLiterals
    assert_respond_to o, :removeLiterals

    assert_raise(StandardError) do
      o.addLiterals(1)
    end

    assert_equal [], o.literals
    o.addLiterals("a")
    assert_equal ["a"], o.literals
    o.addLiterals("b")
    assert_equal ["a", "b"], o.literals
    # check for duplicates works by object identity, so there can be two strings "b"
    o.addLiterals("b")
    assert_equal ["a", "b", "b"], o.literals
    # but the same string object "a" can only occur once
    o.addLiterals(o.literals.first)
    assert_equal ["a", "b", "b"], o.literals
    # removing works by object identity, so providing a new string won't delete an existing one
    o.removeLiterals("a")
    assert_equal ["a", "b", "b"], o.literals
    theA = o.literals.first
    o.removeLiterals(theA)
    assert_equal ["b", "b"], o.literals
    # removing something which is not present has no effect
    o.removeLiterals(theA)
    assert_equal ["b", "b"], o.literals
    o.removeLiterals(o.literals.first)
    assert_equal ["b"], o.literals
    o.removeLiterals(o.literals.first)
    assert_equal [], o.literals
  
    # setting multiple elements at a time
    o.literals = ["a", "b", "c"]
    assert_equal ["a", "b", "c"], o.literals
    # can only take arrays
    assert_raise(StandardError) do
      o.literals = "a"
    end
 
    o.bools = [true, false, true, false]
    assert_equal [true, false], o.bools

    o.integers = [1, 2, 2, 3, 3]
    assert_equal [1, 2, 3], o.integers

    o.enums = [:a, :a, :b, :c, :c]
    assert_equal [:a, :b, :c], o.enums

    lit = ManyAttrClass.ecore.eAttributes.find{|a| a.name == "literals"}
    assert lit.is_a?(RGen::ECore::EAttribute)
    assert lit.many

    lim = ManyAttrClass.ecore.eAttributes.find{|a| a.name == "limitTest"}
    assert lit.many
    assert_equal 2, lim.upperBound
  end

  class ClassA < RGen::MetamodelBuilder::MMBase
    # metamodel accessors must work independent of the ==() method
    module ClassModule
      def ==(o)
        o.is_a?(ClassA)
      end
    end
  end
  
  class ClassB < RGen::MetamodelBuilder::MMBase
  end
  
  class ClassC < RGen::MetamodelBuilder::MMBase
  end
  
  class HasOneTestClass < RGen::MetamodelBuilder::MMBase
    has_one 'classA', ClassA
    has_one 'classB', ClassB
  end
  
  def test_has_one
    sc = HasOneTestClass.new
    assert_respond_to sc, :classA
    assert_respond_to sc, :classA=
    ca = ClassA.new
    sc.classA = ca
    assert_equal ca, sc.classA
    sc.classA = nil
    assert_equal nil, sc.classA
    
    assert_respond_to sc, :classB
    assert_respond_to sc, :classB=
    cb = ClassB.new
    sc.classB = cb
    assert_equal cb, sc.classB
    
    assert_raise StandardError do
      sc.classB = ca
    end
    
    assert_equal [], ClassA.ecore.eReferences
    assert_equal [], ClassB.ecore.eReferences
    assert_equal ["classA", "classB"].sort, HasOneTestClass.ecore.eReferences.name.sort
    assert_equal [], HasOneTestClass.ecore.eReferences.select { |a| a.many == true }
    assert_equal [], HasOneTestClass.ecore.eAttributes
  end
  
  class HasManyTestClass < RGen::MetamodelBuilder::MMBase
    has_many 'classA', ClassA
  end
  
  def test_has_many
    o = HasManyTestClass.new
    ca1 = ClassA.new
    ca2 = ClassA.new
    ca3 = ClassA.new
    o.addClassA(ca1)
    o.addClassA(ca2)
    assert_equal [ca1, ca2], o.classA
    # make sure we get a copy
    o.classA.clear
    assert_equal [ca1, ca2], o.classA
    o.removeClassA(ca3)
    assert_equal [ca1, ca2], o.classA
    o.removeClassA(ca2)
    assert_equal [ca1], o.classA
    assert_raise StandardError do
      o.addClassA(ClassB.new)
    end
    assert_equal [], HasManyTestClass.ecore.eReferences.select{|r| r.many == false}
    assert_equal ["classA"], HasManyTestClass.ecore.eReferences.select{|r| r.many == true}.name
  end
  
  class OneClass < RGen::MetamodelBuilder::MMBase
  end
  class ManyClass < RGen::MetamodelBuilder::MMBase
  end
  OneClass.one_to_many 'manyClasses', ManyClass, 'oneClass', :upperBound => 5
  
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
    
    assert_equal [], OneClass.ecore.eReferences.select{|r| r.many == false}
    assert_equal ["manyClasses"], OneClass.ecore.eReferences.select{|r| r.many == true}.name
    assert_equal 5, OneClass.ecore.eReferences.find{|r| r.many == true}.upperBound
    assert_equal ["oneClass"], ManyClass.ecore.eReferences.select{|r| r.many == false}.name
    assert_equal [], ManyClass.ecore.eReferences.select{|r| r.many == true}
  end
  
  def test_one_to_many_replace1
    oc1 = OneClass.new
    oc2 = OneClass.new
    mc = ManyClass.new  	
    
    oc1.manyClasses = [mc]
    assert_equal [mc], oc1.manyClasses
    assert_equal [], oc2.manyClasses
    assert_equal oc1, mc.oneClass
    
    oc2.manyClasses = [mc]
    assert_equal [mc], oc2.manyClasses
    assert_equal [], oc1.manyClasses
    assert_equal oc2, mc.oneClass
	end

  def test_one_to_many_replace2
    oc = OneClass.new
    mc1 = ManyClass.new  	
    mc2 = ManyClass.new  	
    
    mc1.oneClass = oc
    assert_equal [mc1], oc.manyClasses
    assert_equal oc, mc1.oneClass
    assert_equal nil, mc2.oneClass
    
    mc2.oneClass = oc
    assert_equal [mc1, mc2], oc.manyClasses
    assert_equal oc, mc1.oneClass
    assert_equal oc, mc2.oneClass
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
    
    assert_equal [], OneClass2.ecore.eReferences.select{|r| r.many == false}
    assert_equal ["manyClasses"], OneClass2.ecore.eReferences.select{|r| r.many == true}.name
    assert_equal ["oneClass"], ManyClass2.ecore.eReferences.select{|r| r.many == false}.name
    assert_equal [], ManyClass2.ecore.eReferences.select{|r| r.many == true}
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
    
    assert_equal ["bClass"], AClassOO.ecore.eReferences.select{|r| r.many == false}.name
    assert_equal [], AClassOO.ecore.eReferences.select{|r| r.many == true}
    assert_equal ["aClass"], BClassOO.ecore.eReferences.select{|r| r.many == false}.name
    assert_equal [], BClassOO.ecore.eReferences.select{|r| r.many == true}
  end
  
  def test_one_to_one_replace
    a = AClassOO.new
    b1 = BClassOO.new
    b2 = BClassOO.new
    
    a.bClass = b1
    assert_equal b1, a.bClass
    assert_equal a, b1.aClass
    assert_equal nil, b2.aClass
  
    a.bClass = b2
    assert_equal b2, a.bClass
    assert_equal nil, b1.aClass
    assert_equal a, b2.aClass
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
    
    assert_equal [], AClassMM.ecore.eReferences.select{|r| r.many == false}
    assert_equal  ["bClasses"], AClassMM.ecore.eReferences.select{|r| r.many == true}.name
    assert_equal [], BClassMM.ecore.eReferences.select{|r| r.many == false}
    assert_equal  ["aClasses"], BClassMM.ecore.eReferences.select{|r| r.many == true}.name
  end
  
  class SomeSuperClass < RGen::MetamodelBuilder::MMBase
    has_attr "name"
    has_many "classAs", ClassA
  end
  
  class SomeSubClass < SomeSuperClass
    has_attr "subname"
    has_many "classBs", ClassB
  end
  
  class OtherSubClass < SomeSuperClass
    has_attr "othersubname"
    has_many "classCs", ClassC
  end
  
  def test_inheritance
    assert_equal ["name"], SomeSuperClass.ecore.eAllAttributes.name
    assert_equal ["classAs"], SomeSuperClass.ecore.eAllReferences.name
    assert_equal ["name", "subname"], SomeSubClass.ecore.eAllAttributes.name.sort
    assert_equal ["classAs", "classBs"], SomeSubClass.ecore.eAllReferences.name.sort
    assert_equal ["name", "othersubname"], OtherSubClass.ecore.eAllAttributes.name.sort
    assert_equal ["classAs", "classCs"], OtherSubClass.ecore.eAllReferences.name.sort
  end
  
  module AnnotatedModule 
    extend RGen::MetamodelBuilder::ModuleExtension

    annotation "moduletag" => "modulevalue"
    
    class AnnotatedClass < RGen::MetamodelBuilder::MMBase
      annotation "sometag" => "somevalue", "othertag" => "othervalue"
      annotation :source => "rgen/test", :details => {"thirdtag" => "thirdvalue"}
    
      has_attr "boolAttr", Boolean do
        annotation "attrtag" => "attrval"
        annotation :source => "rgen/test2", :details => {"attrtag2" => "attrvalue2", "attrtag3" => "attrvalue3"}
      end

      has_many "others", AnnotatedClass do
        annotation "reftag" => "refval"
        annotation :source => "rgen/test3", :details => {"reftag2" => "refvalue2", "reftag3" => "refvalue3"}
      end

      many_to_many "m2m", AnnotatedClass, "m2mback" do
        annotation "m2mtag" => "m2mval"
        opposite_annotation "opposite_m2mtag" => "opposite_m2mval"
      end
    end
    
  end
  
  def test_annotations
    assert_equal 1, AnnotatedModule.ecore.eAnnotations.size
    anno = AnnotatedModule.ecore.eAnnotations.first
    checkAnnotation(anno, nil, {"moduletag" => "modulevalue"})

    eClass = AnnotatedModule::AnnotatedClass.ecore
    assert_equal 2, eClass.eAnnotations.size
    anno = eClass.eAnnotations.find{|a| a.source == "rgen/test"}
    checkAnnotation(anno, "rgen/test", {"thirdtag" => "thirdvalue"})
    anno = eClass.eAnnotations.find{|a| a.source == nil}
    checkAnnotation(anno, nil, {"sometag" => "somevalue", "othertag" => "othervalue"})

    eAttr = eClass.eAttributes.first
    assert_equal 2, eAttr.eAnnotations.size
    anno = eAttr.eAnnotations.find{|a| a.source == "rgen/test2"}
    checkAnnotation(anno, "rgen/test2", {"attrtag2" => "attrvalue2", "attrtag3" => "attrvalue3"})
    anno = eAttr.eAnnotations.find{|a| a.source == nil}
    checkAnnotation(anno, nil, {"attrtag" => "attrval"})

    eRef = eClass.eReferences.find{|r| !r.eOpposite}
    assert_equal 2, eRef.eAnnotations.size
    anno = eRef.eAnnotations.find{|a| a.source == "rgen/test3"}
    checkAnnotation(anno, "rgen/test3", {"reftag2" => "refvalue2", "reftag3" => "refvalue3"})
    anno = eRef.eAnnotations.find{|a| a.source == nil}
    checkAnnotation(anno, nil, {"reftag" => "refval"})

    eRef = eClass.eReferences.find{|r| r.eOpposite}
    assert_equal 1, eRef.eAnnotations.size
    anno = eRef.eAnnotations.first
    checkAnnotation(anno, nil, {"m2mtag" => "m2mval"})
    eRef = eRef.eOpposite
    assert_equal 1, eRef.eAnnotations.size
    anno = eRef.eAnnotations.first
    checkAnnotation(anno, nil, {"opposite_m2mtag" => "opposite_m2mval"})
  end

  def checkAnnotation(anno, source, hash)
    assert anno.is_a?(RGen::ECore::EAnnotation)
    assert_equal source, anno.source
    assert_equal hash.size, anno.details.size
    hash.each_pair do |k, v|
      detail = anno.details.find{|d| d.key == k}
      assert detail.is_a?(RGen::ECore::EStringToStringMapEntry)
      assert_equal v, detail.value
    end
  end
  
	module SomePackage 
  	extend RGen::MetamodelBuilder::ModuleExtension
		
		class ClassA < RGen::MetamodelBuilder::MMBase
		end
		
		module SubPackage 
	  	extend RGen::MetamodelBuilder::ModuleExtension
		
			class ClassB < RGen::MetamodelBuilder::MMBase
			end
		end
	end
	
	def test_ecore_identity
		subPackage = SomePackage::SubPackage.ecore
		assert_equal subPackage.eClassifiers.first.object_id, SomePackage::SubPackage::ClassB.ecore.object_id
		
		somePackage = SomePackage.ecore
		assert_equal somePackage.eSubpackages.first.object_id, subPackage.object_id
	end
  
end
