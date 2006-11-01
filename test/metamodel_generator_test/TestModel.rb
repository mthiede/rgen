require 'rgen/metamodel_builder'
module HouseMetamodel

   class Person < RGen::MetamodelBuilder::MMBase
      has_one 'name', String
   end

   class House < RGen::MetamodelBuilder::MMBase
      has_one 'name', String
      has_one 'address', String
   end

   module MeetingPlace
      extend RGen::MetamodelBuilder::BuilderExtensions
      has_one 'name', String
   end


   module Rooms

      class Room < RGen::MetamodelBuilder::MMBase
         has_one 'name', String
      end

      class Bathroom < Room
         has_one 'name', String
      end

      class Kitchen < Room
         include MeetingPlace
         has_one 'name', String
      end

   end
end

HouseMetamodel::Person.one_to_many 'home', HouseMetamodel::House, 'person'
HouseMetamodel::House.one_to_one 'bathroom', HouseMetamodel::Rooms::Bathroom, 'house'
HouseMetamodel::Rooms::Kitchen.one_to_one 'house', HouseMetamodel::House, 'kitchen'
HouseMetamodel::House.one_to_many 'room', HouseMetamodel::Rooms::Room, 'house'
