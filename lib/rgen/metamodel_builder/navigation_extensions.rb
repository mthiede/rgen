# RGen Framework
# (c) Martin Thiede, 2006

require 'erb'
require 'rgen/metamodel_builder/intermediate/feature'

module RGen

module MetamodelBuilder

# This module is intended to be included in a class extending MMBase
# to plug-in additional functionalities to navigate the model
module NavigationExtensions

  # Return the root of the model
  def root(of=self)
    return of unless of.eContainer
    root(of.eContainer)
  end  

end

end

end
