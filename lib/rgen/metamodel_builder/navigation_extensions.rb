# RGen Framework

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

end

end

end
