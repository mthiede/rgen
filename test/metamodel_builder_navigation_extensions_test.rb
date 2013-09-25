$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'
require 'rgen/array_extensions'
require 'bigdecimal'

class MetamodelBuilderNavigationExtensionsTest < Test::Unit::TestCase
  
  module TestMetamodel

    class Address < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::NavigationExtensions
      has_attr 'type', String
      has_attr 'street', String
      has_attr 'number', String
    end

    class AddressBookEntry < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::NavigationExtensions
      has_attr 'name', String
      contains_many_uni 'addresses', Address
    end

    class AddressBook < RGen::MetamodelBuilder::MMBase
      contains_many_uni 'entries', AddressBookEntry
    end

  end
   
  def mm
    TestMetamodel
  end

  def test_root_method_is_there
    a = TestMetamodel::Address.new
    assert a.respond_to?(:root)
  end

  def test_root_is_self_object_for_dangling_object
    a = TestMetamodel::Address.new
    assert a==a.root
  end

  def test_root_is_direct_container
    a1 = TestMetamodel::Address.new
    a1.type = 'work'
    a2 = TestMetamodel::Address.new
    a2.type = 'home'    
    abe = TestMetamodel::AddressBookEntry.new
    abe.addAddresses(a1)
    abe.addAddresses(a2)
    assert abe==a1.root
    assert abe==a2.root
    assert abe==abe.root
  end

  # It works even is the top container
  # has not the extension
  def test_root_is_top_container
    a1 = TestMetamodel::Address.new
    a1.type = 'work'
    a2 = TestMetamodel::Address.new
    a2.type = 'home'    
    abe = TestMetamodel::AddressBookEntry.new
    abe.name = 'Mr. Jones'
    abe.addAddresses(a1)
    abe.addAddresses(a2)
    ab = TestMetamodel::AddressBook.new
    ab.addEntries(abe)
    assert ab==a1.root
    assert ab==a2.root
    assert ab==abe.root
  end  

end
