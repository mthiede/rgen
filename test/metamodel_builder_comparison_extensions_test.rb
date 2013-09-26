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

  raise "write the tests!"

end
