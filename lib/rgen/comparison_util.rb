# RGen Framework

module RGen

module ComparisonUtil

  module ShallowComparator

    # It does not check references, so that infinite recursion
    # is avoided
    def self.eql?(left,right)
      return false if right==nil
      return false unless left.class==right.class
      left.class.ecore.eAllAttributes.each do |attribute|
        raise "Attrib <nil> for class #{left.class.ecore.name}" unless attribute
        left_value  = left.send(attribute.name)
        right_value = right.send(attribute.name)
        return false unless left_value.eql?(right_value)
      end
      true
    end  

  end

  module DeepComparator

    # It checks all the containment references recursively
    # while it compare the non-containment references using
    # ShallowComparator, to avoid infinite recursion
    def self.eql?(left,right)    
      return false unless ShallowComparator.eql?(left,right)
      left.class.ecore.eAllReferences.each do |ref|
        left_value = left.send(ref.name)
        right_value = right.send(ref.name)
        # it should ignore relations which has as opposite a containment
        unless (ref.getEOpposite and ref.getEOpposite.containment)
          comparison_method = ref.containment ? DeepComparator : ShallowComparator
          if left_value==nil || right_value==nil          
            # if one value is nil, both should be nil
            return false unless left_value==right_value
          elsif ref.many
            # compare each children
            return false unless left_value.count==right_value.count
            for i in 0...left_value.count             
              return false unless comparison_method.send(:eql?,left_value[i],right_value[i])      
            end
          else              
            # compare the only child
            return false unless comparison_method.send(:eql?,left_value,right_value)                                             
          end
        end           
      end
      true    
    end

  end

end

end
