require 'rgen/metamodel_builder'

module HouseMetamodel
   extend RGen::ECore::ECoreInstantiator
   include RGen::MetamodelBuilder::DataTypes


   class MeetingPlace < RGen::MetamodelBuilder::MMBase
   end

   class House < RGen::MetamodelBuilder::MMBase
      has_attr 'address', String, :changeable => false
   end

   class Person < RGen::MetamodelBuilder::MMBase
   end


   module Rooms
      extend RGen::ECore::ECoreInstantiator
      include RGen::MetamodelBuilder::DataTypes


      class Room < RGen::MetamodelBuilder::MMBase
      end

      class Bathroom < Room
      end

      class Kitchen < RGen::MetamodelBuilder::MMMultiple(HouseMetamodel::MeetingPlace, Room)
      end

   end
end

HouseMetamodel::House.has_one 'bathroom', HouseMetamodel::Rooms::Bathroom, :lowerBound => 1
HouseMetamodel::House.one_to_one 'kitchen', HouseMetamodel::Rooms::Kitchen, 'house', :lowerBound => 1
HouseMetamodel::House.contains_many 'room', HouseMetamodel::Rooms::Room, 'house', :lowerBound => 1
HouseMetamodel::Person.has_many 'home', HouseMetamodel::House
