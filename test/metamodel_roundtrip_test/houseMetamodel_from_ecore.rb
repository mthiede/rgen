require 'rgen/metamodel_builder'

module HouseMetamodel
   extend RGen::MetamodelBuilder::ModuleExtension
   include RGen::MetamodelBuilder::DataTypes


   class House < RGen::MetamodelBuilder::MMBase
      has_attr 'address', String, :ordered => :true, :unique => :true, :changeable => false, :volatile => :false, :transient => :false, :unsettable => :false, :derived => :false 
   end

   class MeetingPlace < RGen::MetamodelBuilder::MMBase
   end

   class Person < RGen::MetamodelBuilder::MMBase
   end


   module Rooms
      extend RGen::MetamodelBuilder::ModuleExtension
      include RGen::MetamodelBuilder::DataTypes


      class Room < RGen::MetamodelBuilder::MMBase
      end

      class Bathroom < Room
      end

      class Kitchen < RGen::MetamodelBuilder::MMMultiple(Room, HouseMetamodel::MeetingPlace)
      end

   end
end

HouseMetamodel::House.contains_one_uni 'bathroom', HouseMetamodel::Rooms::Bathroom, :ordered => true, :unique => true, :changeable => true, :volatile => false, :transient => false, :unsettable => false, :derived => false, :lowerBound => 1, :resolveProxies => true 
HouseMetamodel::Rooms::Kitchen.contains_one 'house', HouseMetamodel::House, 'kitchen', :ordered => true, :unique => true, :changeable => true, :volatile => false, :transient => false, :unsettable => false, :derived => false, :resolveProxies => true, :opposite_ordered => true, :opposite_unique => true, :opposite_changeable => true, :opposite_volatile => false, :opposite_transient => false, :opposite_unsettable => false, :opposite_derived => false, :opposite_lowerBound => 1, :opposite_resolveProxies => true 
HouseMetamodel::Rooms::Room.many_to_one 'house', HouseMetamodel::House, 'room', :ordered => true, :unique => true, :changeable => true, :volatile => false, :transient => false, :unsettable => false, :derived => false, :resolveProxies => true, :opposite_ordered => true, :opposite_unique => true, :opposite_changeable => true, :opposite_volatile => false, :opposite_transient => false, :opposite_unsettable => false, :opposite_derived => false, :opposite_resolveProxies => true 
HouseMetamodel::Person.contains_many_uni 'house', HouseMetamodel::House, :ordered => true, :unique => true, :changeable => true, :volatile => false, :transient => false, :unsettable => false, :derived => false, :resolveProxies => true 
