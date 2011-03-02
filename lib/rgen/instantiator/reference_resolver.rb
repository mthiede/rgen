module RGen

module Instantiator

# This module is meant to be mixed into a resolver class providing the method +resolveIdentifier+
module ReferenceResolver
 
  # Instances of this class represent information about not yet resolved references.
  # This consists of the +element+ and metamodel +featureName+ which hold/is to hold the reference
  # and the proxy +object+ which is the placeholder for the reference.
  # optionally the +file+ and +line+ of the reference may be specified
  class UnresolvedReference 
    attr_reader :element, :featureName, :proxy, :line
    attr_accessor :file
    def initialize(element, featureName, proxy, options={})
      @element = element
      @featureName = featureName
      @proxy = proxy
      @file = options[:file]
      @line = options[:line]
    end
  end

  # tries to resolve the given +unresolvedReferences+
  # if resolution is successful, the proxy object will be removed
  # otherwise there will be an error description in +problems+
  # returns an array of the references which are still unresolved
  def resolveReferences(unresolvedReferences, problems=[])
    stillUnresolvedReferences = []
    unresolvedReferences.each do |ur|
      target = resolveIdentifier(ur.proxy.targetIdentifier)
      if target && !target.is_a?(Array)
        if ur.element.hasManyMethods(ur.featureName)
          ur.element.removeGeneric(ur.featureName, ur.proxy)
          ur.element.addGeneric(ur.featureName, target)
        else
          # this will replace the proxy
          ur.element.setGeneric(ur.featureName, target)
        end
      elsif target
        problems << "identifier #{ur.proxy.targetIdentifier} not uniq"
        stillUnresolvedReferences << ur
      else
        problems << "identifier #{ur.proxy.targetIdentifier} not found"
        stillUnresolvedReferences << ur
      end
    end
    stillUnresolvedReferences
  end   

end

end

end
