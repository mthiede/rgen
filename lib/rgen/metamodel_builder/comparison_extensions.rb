# RGen Framework

module RGen

module MetamodelBuilder

# This module is intended to be included in a class extending MMBase
# to plug-in additional functionalities to compare sub-trees
#
# The methods use a parameter is used to make the method
# work on elements of the subtree which do not include
# this module
module ComparisonExtensions

  # It does not check references, it is needed to avoid infinite recursion
  def shallow_same_content?(of=self,other)
    return false if other==nil
    return false unless of.class==other.class
    of.class.ecore.eAllAttributes.each do |attrib|
      raise "Attrib <nil> for class #{of.class.ecore.name}" unless attrib
      self_value  = of.send(attrib.name)
      other_value = other.send(attrib.name)
      return false unless self_value == other_value
    end
    true
  end  

  def same_content?(of=self,other)    
    return false unless shallow_same_content?(of,other)
    of.class.ecore.eAllReferences.each do |ref|
      self_value = of.send(ref.name)
      other_value = other.send(ref.name)
      # it should ignore relations which has as opposite a containment
      unless (ref.getEOpposite and ref.getEOpposite.containment)
        comparison_method = ref.containment ? :same_content? : :shallow_same_content?
        if self_value==nil || other_value==nil          
          # if one value is false, both should be false
          return false unless self_value==other_value        
        elsif ref.many
          # compare each children
          return false unless self_value.count==other_value.count
          for i in 0...self_value.count             
            return false unless send(comparison_method,self_value[i],other_value[i])      
          end
        else              
          # compare the only child
          return false unless send(comparison_method,self_value,other_value)                                             
        end
      end           
    end
    true    
  end

end

end

end
