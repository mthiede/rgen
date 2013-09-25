# RGen Framework
# (c) Martin Thiede, 2006

require 'erb'
require 'rgen/metamodel_builder/intermediate/feature'

module RGen

module MetamodelBuilder

# This module is intended to be included in a class extending MMBase
# to plug-in additional functionalities to navigate the model
#
# The methods use a parameter is used to make the method
# work on elements of the subtree which do not include
# this module
module NavigationExtensions

  # Return the root of the model
  def root(of=self)
    return of unless of.eContainer
    root(of.eContainer)
  end  

  def all_children(of=self)
    arr = []
    ecore = of.class.ecore
    ecore.eAllReferences.select {|r| r.containment}.each do |ref|
      res = of.send(ref.name.to_sym)
      if ref.many
        d = arr.count
        res.each do |el|
          arr << el unless res==nil
        end
      elsif res!=nil
        d = arr.count
        arr << res
      end
    end
    arr
  end

  def all_children_deep(of=self)
    arr = []
    of.all_children.each do |c|
      arr << c
      c.all_children_deep.each do |cc|
        arr << cc
      end
    end     
    arr
  end

  # The node itself and all the node in the sub-tree
  # are passed to the given block
  def traverse(&op)
    op.call(self)
    all_children_deep.each do |c|
      op.call(c)
    end
  end  

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
