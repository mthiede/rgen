# RGen Framework

module RGen

module ComparisonUtil

  # It does not check references, it is needed to avoid infinite recursion
  def self.shallow_same_content?(first,other)
    return false if other==nil
    return false unless first.class==other.class
    first.class.ecore.eAllAttributes.each do |attrib|
      raise "Attrib <nil> for class #{first.class.ecore.name}" unless attrib
      self_value  = first.send(attrib.name)
      other_value = other.send(attrib.name)
      return false unless self_value == other_value
    end
    true
  end  

  def self.same_content?(first,other)    
    return false unless shallow_same_content?(first,other)
    first.class.ecore.eAllReferences.each do |ref|
      self_value = first.send(ref.name)
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
