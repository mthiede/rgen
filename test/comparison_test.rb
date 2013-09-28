$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'test/unit'
require 'rgen/metamodel_builder'
require 'rgen/comparison'

class ComparisonTest < Test::Unit::TestCase
  
  include RGen::Comparison

  module OrderedTestMetamodel

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

  module UnorderedTestMetamodel

    class Country < RGen::MetamodelBuilder::MMBase
      has_many_attr 'qualities', String, ordered: false
    end

    class World < RGen::MetamodelBuilder::MMBase
      contains_many_uni 'countries', Country, ordered: false
    end

  end
   
  def setup
    # Ordered data

    @jones_work_address = OrderedTestMetamodel::Address.new
    @jones_work_address.type = 'work'

    @jones_home_address = OrderedTestMetamodel::Address.new
    @jones_home_address.type = 'home'    

    @jones_book_entry = OrderedTestMetamodel::AddressBookEntry.new
    @jones_book_entry.name = 'Mr. Jones'
    @jones_book_entry.addAddresses(@jones_work_address)
    @jones_book_entry.addAddresses(@jones_home_address)

    @smith_shop_address = OrderedTestMetamodel::Address.new
    @smith_shop_address.type = 'shop'

    @smith_home_address = OrderedTestMetamodel::Address.new
    @smith_home_address.type = 'home'      

    @smith_book_entry = OrderedTestMetamodel::AddressBookEntry.new
    @smith_book_entry.name = 'Mr. Smith'
    @smith_book_entry.addAddresses(@smith_shop_address)
    @smith_book_entry.addAddresses(@smith_home_address)

    @green_book_entry = OrderedTestMetamodel::AddressBookEntry.new
    @green_book_entry.name = 'Mr. Green'

    @address_book_1 = OrderedTestMetamodel::AddressBook.new
    @address_book_1.addEntries(@jones_book_entry)
    @address_book_1.addEntries(@smith_book_entry)
    @address_book_1.addEntries(@green_book_entry)

    # Unordered data

    @c_1 = UnorderedTestMetamodel::Country.new
    @c_1.addQualities 'sunny'
    @c_1.addQualities 'open-minded'
    
    @c_2 = UnorderedTestMetamodel::Country.new
    @c_2.addQualities 'open-minded'
    @c_2.addQualities 'sunny'
    
    @c_3 = UnorderedTestMetamodel::Country.new
    @c_3.addQualities 'open-minded'
    @c_3.addQualities 'sunny'
    @c_3.addQualities 'sunny'
    
    @c_4 = UnorderedTestMetamodel::Country.new
    @c_4.addQualities 'open-minded'
    @c_4.addQualities 'open-minded'

    @world_1 = UnorderedTestMetamodel::World.new    
    @world_1.addCountries @c_1
    @world_1.addCountries @c_2
    @world_1.addCountries @c_3

    @world_2 = UnorderedTestMetamodel::World.new
    @world_2.addCountries @c_2
    @world_2.addCountries @c_1
    @world_2.addCountries @c_3
    
    @world_3 = UnorderedTestMetamodel::World.new
    @world_3.addCountries @c_3
    @world_3.addCountries @c_1
    @world_3.addCountries @c_2    

    @world_4 = UnorderedTestMetamodel::World.new
    @world_4.addCountries @c_2
    @world_4.addCountries @c_1
    @world_4.addCountries @c_2     
  end

  def test_deep_comparator_based_on_unordered_attributes
    assert_equal true, DeepComparator.eql?(@c_1,@c_1)
    assert_equal true, DeepComparator.eql?(@c_1,@c_2)
    assert_equal false,DeepComparator.eql?(@c_1,@c_3)
    assert_equal false,DeepComparator.eql?(@c_1,@c_4)
    assert_equal true, DeepComparator.eql?(@c_2,@c_1)
    assert_equal true, DeepComparator.eql?(@c_2,@c_2)
    assert_equal false,DeepComparator.eql?(@c_2,@c_3)
    assert_equal false,DeepComparator.eql?(@c_2,@c_4)
    assert_equal false,DeepComparator.eql?(@c_3,@c_1)
    assert_equal false,DeepComparator.eql?(@c_3,@c_2)
    assert_equal true, DeepComparator.eql?(@c_3,@c_3)
    assert_equal false,DeepComparator.eql?(@c_3,@c_4)
    assert_equal false,DeepComparator.eql?(@c_4,@c_1)
    assert_equal false,DeepComparator.eql?(@c_4,@c_2)
    assert_equal false,DeepComparator.eql?(@c_4,@c_3)
    assert_equal true, DeepComparator.eql?(@c_4,@c_4)    
  end

  def test_shallow_comparator_based_on_unordered_attributes
    assert_equal true, ShallowComparator.eql?(@c_1,@c_1)
    assert_equal true, ShallowComparator.eql?(@c_1,@c_2)
    assert_equal false,ShallowComparator.eql?(@c_1,@c_3)
    assert_equal false,ShallowComparator.eql?(@c_1,@c_4)
    assert_equal true, ShallowComparator.eql?(@c_2,@c_1)
    assert_equal true, ShallowComparator.eql?(@c_2,@c_2)
    assert_equal false,ShallowComparator.eql?(@c_2,@c_3)
    assert_equal false,ShallowComparator.eql?(@c_2,@c_4)
    assert_equal false,ShallowComparator.eql?(@c_3,@c_1)
    assert_equal false,ShallowComparator.eql?(@c_3,@c_2)
    assert_equal true, ShallowComparator.eql?(@c_3,@c_3)
    assert_equal false,ShallowComparator.eql?(@c_3,@c_4)
    assert_equal false,ShallowComparator.eql?(@c_4,@c_1)
    assert_equal false,ShallowComparator.eql?(@c_4,@c_2)
    assert_equal false,ShallowComparator.eql?(@c_4,@c_3)
    assert_equal true, ShallowComparator.eql?(@c_4,@c_4)    
  end  

  def test_deep_comparator_based_on_unordered_references
    assert_equal true,  DeepComparator.eql?(@world_1,@world_1)
    assert_equal true, DeepComparator.eql?(@world_1,@world_2)
    assert_equal true, DeepComparator.eql?(@world_1,@world_3)
    assert_equal false, DeepComparator.eql?(@world_1,@world_4)
    assert_equal true, DeepComparator.eql?(@world_2,@world_1)
    assert_equal true,  DeepComparator.eql?(@world_2,@world_2)
    assert_equal true, DeepComparator.eql?(@world_2,@world_3)
    assert_equal false, DeepComparator.eql?(@world_2,@world_4)
    assert_equal true, DeepComparator.eql?(@world_3,@world_1)
    assert_equal true, DeepComparator.eql?(@world_3,@world_2)
    assert_equal true,  DeepComparator.eql?(@world_3,@world_3)
    assert_equal false, DeepComparator.eql?(@world_3,@world_4)    
    assert_equal false, DeepComparator.eql?(@world_4,@world_1)
    assert_equal false, DeepComparator.eql?(@world_4,@world_2)
    assert_equal false, DeepComparator.eql?(@world_4,@world_3)
    assert_equal true,  DeepComparator.eql?(@world_4,@world_4)    
  end    

  def test_deep_comparator_based_on_ordered_attributes_positive_case
      same_as_jones_work_address = OrderedTestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      assert_equal true,DeepComparator.eql?(same_as_jones_work_address,@jones_work_address)
      assert_equal true,DeepComparator.eql?(@jones_work_address,same_as_jones_work_address)
  end

  def test_deep_comparator_based_on_ordered_attributes_negative_case
      assert_equal false,DeepComparator.eql?(@jones_work_address,@jones_home_address)
      assert_equal false,DeepComparator.eql?(@jones_home_address,@jones_work_address)
  end  

  def test_shallow_comparator_based_on_ordered_attributes_negative_case
      assert_equal false,ShallowComparator.eql?(@jones_home_address,@jones_work_address)
      assert_equal false,ShallowComparator.eql?(@jones_work_address,@jones_home_address)
  end  

  def test_shallow_comparator_based_on_ordered_attributes_positive_case
      same_as_jones_work_address = OrderedTestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      assert_equal true,ShallowComparator.eql?(same_as_jones_work_address,@jones_work_address)
      assert_equal true,ShallowComparator.eql?(@jones_work_address,same_as_jones_work_address)
  end

  def test_shallow_comparator_based_on_ordered_attributes_and_children
      same_as_jones_work_address = OrderedTestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      same_as_jones_home_address = OrderedTestMetamodel::Address.new
      same_as_jones_home_address.type = 'home'
      
      similar_to_jones_book_entry = OrderedTestMetamodel::AddressBookEntry.new
      similar_to_jones_book_entry.name = 'Mr. Jones'

      assert_equal true,ShallowComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)

      similar_to_jones_book_entry.addAddresses(same_as_jones_work_address)
      similar_to_jones_book_entry.addAddresses(same_as_jones_home_address)

      assert_equal true,ShallowComparator.eql?(@jones_home_address,same_as_jones_home_address)
      assert_equal true,ShallowComparator.eql?(@jones_work_address,same_as_jones_work_address)
      assert_equal true,ShallowComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)      
  end 

  def test_deep_comparator_based_on_ordered_attributes_and_children
      same_as_jones_work_address = OrderedTestMetamodel::Address.new
      same_as_jones_work_address.type = 'work'

      same_as_jones_home_address = OrderedTestMetamodel::Address.new
      same_as_jones_home_address.type = 'home'
      
      similar_to_jones_book_entry = OrderedTestMetamodel::AddressBookEntry.new
      similar_to_jones_book_entry.name = 'Mr. Jones'

      assert_equal false,DeepComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)

      similar_to_jones_book_entry.addAddresses(same_as_jones_work_address)
      similar_to_jones_book_entry.addAddresses(same_as_jones_home_address)

      assert_equal true,DeepComparator.eql?(@jones_home_address,same_as_jones_home_address)
      assert_equal true,DeepComparator.eql?(@jones_work_address,same_as_jones_work_address)
      assert_equal true,DeepComparator.eql?(@jones_book_entry,similar_to_jones_book_entry)      
  end  

end
