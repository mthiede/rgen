# RGen Framework
# (c) Martin Thiede, 2006

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
    return false unless self.class==other.class
    self.class.ecore.eAllAttributes.each do |attrib|
      raise "Attrib <nil> for class #{self.class.ecore.name}" unless attrib
      if attrib.name != 'dynamic' # I have to understand this...
        self_value  = self.get(attrib)
        other_value = other.get(attrib)
        return false unless self_value == other_value
      end
    end
    true
  end  

  def same_content?(of=self,other)    
    return false unless shallow_same_content?(self,other)
    self.class.ecore.eAllReferences.each do |ref|
      self_value = self.get(ref)
      other_value = other.get(ref)
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
