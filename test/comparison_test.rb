$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'
require 'rgen/comparison'

class ComparisonTest < Test::Unit::TestCase
  
  include RGen::Comparison

  module TestMetamodel

    class Address < RGen::MetamodelBuilder::MMBase
      has_attr 'type', String
      has_attr 'street', String
      has_attr 'number', String
    end

    class AddressBookEntry < RGen::MetamodelBuilder::MMBase
      has_attr 'name', String
      contains_many_uni 'addresses', Address
    end

    class AddressBook < RGen::MetamodelBuilder::MMBase
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

  def test_deep_comparator_based_on_attributes_positive_case
      same_as_jones_work_address = TestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      assert_equal true,DeepComparator.eql?(same_as_jones_work_address,@jones_work_address)
      assert_equal true,DeepComparator.eql?(@jones_work_address,same_as_jones_work_address)
  end

  def test_deep_comparator_based_on_attributes_negative_case
      assert_equal false,DeepComparator.eql?(@jones_work_address,@jones_home_address)
      assert_equal false,DeepComparator.eql?(@jones_home_address,@jones_work_address)
  end  

  def test_shallow_comparator_based_on_attributes_negative_case
      assert_equal false,ShallowComparator.eql?(@jones_home_address,@jones_work_address)
      assert_equal false,ShallowComparator.eql?(@jones_work_address,@jones_home_address)
  end  

  def test_shallow_comparator_based_on_attributes_positive_case
      same_as_jones_work_address = TestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      assert_equal true,ShallowComparator.eql?(same_as_jones_work_address,@jones_work_address)
      assert_equal true,ShallowComparator.eql?(@jones_work_address,same_as_jones_work_address)
  end

  def test_shallow_comparator_based_on_attributes_and_children
      same_as_jones_work_address = TestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      same_as_jones_home_address = TestMetamodel::Address.new
      same_as_jones_home_address.type = 'home'
      
      similar_to_jones_book_entry = TestMetamodel::AddressBookEntry.new
      similar_to_jones_book_entry.name = 'Mr. Jones'

      assert_equal true,ShallowComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)

      similar_to_jones_book_entry.addAddresses(same_as_jones_work_address)
      similar_to_jones_book_entry.addAddresses(same_as_jones_home_address)

      assert_equal true,ShallowComparator.eql?(@jones_home_address,same_as_jones_home_address)
      assert_equal true,ShallowComparator.eql?(@jones_work_address,same_as_jones_work_address)
      assert_equal true,ShallowComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)      
  end 

  def test_deep_comparator_based_on_attributes_and_children
      same_as_jones_work_address = TestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      same_as_jones_home_address = TestMetamodel::Address.new
      same_as_jones_home_address.type = 'home'
      
      similar_to_jones_book_entry = TestMetamodel::AddressBookEntry.new
      similar_to_jones_book_entry.name = 'Mr. Jones'

      assert_equal false,DeepComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)

      similar_to_jones_book_entry.addAddresses(same_as_jones_work_address)
      similar_to_jones_book_entry.addAddresses(same_as_jones_home_address)

      assert_equal true,DeepComparator.eql?(@jones_home_address,same_as_jones_home_address)
      assert_equal true,DeepComparator.eql?(@jones_work_address,same_as_jones_work_address)
      assert_equal true,DeepComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)      
  end  

end
