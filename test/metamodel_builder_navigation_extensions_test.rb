$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'

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
      include RGen::MetamodelBuilder::NavigationExtensions
      contains_many_uni 'entries', AddressBookEntry
    end

  end
   
  def setup
    @jones_work_address = TestMetamodel::Address.new
    @jones_work_address.type = 'work'

    @jones_home_address = TestMetamodel::Address.new
    @jones_home_address.type = 'home'    

    @jones_book_entry = TestMetamodel::AddressBookEntry.new
    @jones_book_entry.name = 'Mr. Jones'
    @jones_book_entry.addAddresses(@jones_work_address)
    @jones_book_entry.addAddresses(@jones_home_address)

    @smith_shop_address = TestMetamodel::Address.new
    @smith_shop_address.type = 'shop'

    @smith_home_address = TestMetamodel::Address.new
    @smith_home_address.type = 'home'      

    @smith_book_entry = TestMetamodel::AddressBookEntry.new
    @smith_book_entry.name = 'Mr. Smith'
    @smith_book_entry.addAddresses(@smith_shop_address)
    @smith_book_entry.addAddresses(@smith_home_address)

    @green_book_entry = TestMetamodel::AddressBookEntry.new
    @green_book_entry.name = 'Mr. Green'

    @address_book_1 = TestMetamodel::AddressBook.new
    @address_book_1.addEntries(@jones_book_entry)
    @address_book_1.addEntries(@smith_book_entry)
    @address_book_1.addEntries(@green_book_entry)
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

  def test_all_children_empty
    # this node has not containment relations
    assert_equal [],@jones_work_address.all_children
    # this node has containment relations
    assert_equal [],@green_book_entry.all_children
  end

  def test_all_children_not_empty
    assert_equal(
      [@jones_book_entry,@smith_book_entry,@green_book_entry], 
      @address_book_1.all_children)
  end 

  def test_all_children_deep_not_empty
    assert_equal 7,@address_book_1.all_children_deep.count
    # direct children
    assert @address_book_1.all_children_deep.include?(
      @jones_book_entry)
    assert @address_book_1.all_children_deep.include?(
      @smith_book_entry)
    assert @address_book_1.all_children_deep.include?(
      @green_book_entry)
    # non-direct children
    assert @address_book_1.all_children_deep.include?(
      @jones_work_address)
    assert @address_book_1.all_children_deep.include?(
      @jones_home_address)    
    assert @address_book_1.all_children_deep.include?(
      @smith_shop_address)
    assert @address_book_1.all_children_deep.include?(
      @smith_home_address)        
  end    

  def test_traverse
    to_traverse = [@address_book_1,
        @jones_book_entry,
          @jones_work_address,@jones_home_address,
        @smith_book_entry,
          @smith_shop_address,@smith_home_address,
        @green_book_entry]            
    i = 0  
    @address_book_1.traverse do |c|
      exp = to_traverse[i]
      assert_equal exp,c,"At position #{i} expected to traverse: #{exp}, found: #{c}"
      i+=1
    end
    assert_equal to_traverse.count,i,'Not traversed as many as expected'
  end

end
