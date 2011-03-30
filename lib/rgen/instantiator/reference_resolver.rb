module RGen

module Instantiator

# The ReferenceResolver can be used to resolve unresolved references, i.e. instances
# of class UnresolvedReference
#
# There are two ways how this can be used:
#  1. the identifiers and associated model elements are added upfront using +add_identifier+
#  2. register an :identifier_resolver with the constructor, which will be invoked 
#     for every unresolved identifier
#
class ReferenceResolver
 
  # Instances of this class represent information about not yet resolved references.
  # This consists of the +element+ and metamodel +feature_name+ which hold/is to hold the 
  # reference and the +proxy+ object which is the placeholder for the reference.
  #
  class UnresolvedReference 
    attr_reader :feature_name, :proxy
    attr_accessor :element
    def initialize(element, feature_name, proxy, options={})
      @element = element
      @feature_name = feature_name
      @proxy = proxy
    end
  end

  # Create a reference resolver, options:
  #
  #  :identifier_resolver:
  #    a proc which is called with an identifier and which should return the associated element
  #    in case the identifier is not uniq, the proc may return multiple values
  #    default: lookup element in internal map
  #
  def initialize(options={})
    @identifier_resolver = options[:identifier_resolver]
    @identifier_map = {}
  end

  # Add an +identifer+ / +element+ pair which will be used for looking up unresolved identifers
  def add_identifier(ident, element)
    map_entry = @identifier_map[ident]
    if map_entry 
      if map_entry.is_a?(Array)
        map_entry << element
      else
        @identifier_map[ident] = [map_entry, element]
      end
    else 
      @identifier_map[ident] = element
    end
  end

  # Tries to resolve the given +unresolved_refs+
  # if resolution is successful, the proxy object will be removed, otherwise there will be an 
  # error description in +problems+
  # returns an array of the references which are still unresolved
  def resolve(unresolved_refs, problems=[])
    still_unresolved_refs = []
    unresolved_refs.each do |ur|
      if @identifier_resolver
        target = @identifier_resolver.call(ur.proxy.targetIdentifier)
      else
        target = @identifier_map[ur.proxy.targetIdentifier]
      end
      target = [target].compact unless target.is_a?(Array)
      if target.size == 1
        if ur.element.hasManyMethods(ur.feature_name)
          ur.element.removeGeneric(ur.feature_name, ur.proxy)
          ur.element.addGeneric(ur.feature_name, target[0])
        else
          # this will replace the proxy
          ur.element.setGeneric(ur.feature_name, target[0])
        end
      elsif target.size > 1
        problems << "identifier #{ur.proxy.targetIdentifier} not uniq"
        still_unresolved_refs << ur
      else
        problems << "identifier #{ur.proxy.targetIdentifier} not found"
        still_unresolved_refs << ur
      end
    end
    still_unresolved_refs
  end   

end

end

end
