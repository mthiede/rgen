require 'rgen/instantiator/reference_resolver'

module RGen

module Fragment

# A FragmentedModel represents a model which consists of fragments (ModelFragment).
# 
# The main purpose of this class is to resolve references across fragments and
# to keep the references consistent while fragments are added or removed.
# This way it also plays an important role in keeping the model fragments consistent
# and thus ModelFragment objects should only be accessed via this interface.
# Overall unresolved references after the resolution step are also maintained.
#
# A FragmentedModel can also  keep an RGen::Environment object up to date while fragments
# are added or removed. The environment must be registered with the constructor.
#
# Reference resolution is based on arbitrary identifiers. The identifiers must be
# provided in the fragments' indices. The FragmentedModel takes care to maintain
# the overall index.
#
class FragmentedModel
  attr_reader :fragments
  attr_reader :environment

  # Creates a fragmented model. Options:
  #
  #  :env 
  #    environment which will be updated as model elements are added and removed
  #
  def initialize(options={})
    @environment = options[:env]
    @fragments = []
    @index = nil
    @unresolved_refs = nil
    @ref_has_uref = {}
    @fragment_change_listeners = []
  end

  # Adds a proc which is called when a fragment is added or removed
  # The proc receives the fragment and one of :added, :removed
  #
  def add_fragment_change_listener(listener)
    @fragment_change_listeners << listener
  end

  def remove_fragment_change_listener(listener)
    @fragment_change_listeners.delete(listener)
  end

  # Add a fragment.
  #
  def add_fragment(fragment)
    invalidate_cache
    @fragments << fragment
    fragment.elements.each{|e| @environment << e} if @environment
    @fragment_change_listeners.each{|l| l.call(fragment, :added)}
  end

  # Removes the fragment. The fragment will be unresolved using unresolve_fragment.
  # If a +fragment_provider+ is given it will be faster, see unresolve_fragment.
  #
  def remove_fragment(fragment, fragment_provider=nil)
    raise "fragment not part of model" unless @fragments.include?(fragment)
    invalidate_cache
    @fragments.delete(fragment)
    unresolve_fragment(fragment, fragment_provider)
    fragment.elements.each{|e| @environment.delete(e)} if @environment
    @fragment_change_listeners.each{|l| l.call(fragment, :removed)}
  end

  # Remove all references between this fragment and all other fragments.
  # The references will be replaced with unresolved references (MMProxy objects).
  #
  # If a +fragment_provider+ is given, the unresolve step can be performed
  # much more efficiently. The fragment provider is a proc which receives a model
  # element and must return the fragment in which the element is contained or
  # null in case this information is not available. If the fragment is known
  # for all elements which are disconnected in one unresolve step, this step will 
  # be significantly faster.
  #
  def unresolve_fragment(fragment, fragment_provider=nil)
    invalidate_urefs
    unknown_fragments = false
    fragment.unresolve(
      proc {|ref| @ref_has_uref.has_key?([ref.eContainingClass, ref.name])},
      proc {|element| reverse_index[element] },
      proc {|element| 
        frag = fragment_provider && fragment_provider.call(element)
        unknown_fragments = true unless frag
        frag})
    if unknown_fragments
      @fragments.each do |f| 
        f.refs_changed if f != fragment
      end
    end
  end

  # Resolve references between fragments. 
  # It is assumed that references within fragments have already been resolved.
  # This method can be called several times. 
  # It will updated the overall unresolved references.
  # If +fragment_provider+ is given future resolve steps will be faster since
  # unresolved reference caches can be reused, see unresolve_fragment
  #
  def resolve(fragment_provider=nil)
    urefs = []
    @fragments.each{|f| urefs.concat(f.unresolved_refs)}
    urefs.each do |ur|
      # remember that an unresolved reference was seen for the EReference
      @ref_has_uref[[ur.element.class.ecore, ur.feature_name]] = true
    end
    resolver = RGen::Instantiator::ReferenceResolver.new(
      :identifier_resolver => proc do |ident|
        index[ident]
      end)
    @unresolved_refs = resolver.resolve(urefs)
    if fragment_provider
      unknown_fragments = false
      urefs_by_fragment = {}
      (urefs - @unresolved_refs).each do |ur|
        fr = fragment_provider.call(ur.element)
        if fr
          urefs_by_fragment[fr] ||= []
          urefs_by_fragment[fr] << ur
        else
          unknown_fragments = true
        end
      end
      if unknown_fragments
        @fragments.each{|f| f.refs_changed}
      else
        urefs_by_fragment.each_pair do |fr, urefs|
          fr.remove_unresolved_refs(urefs)
        end
      end
    else
      @fragments.each{|f| f.refs_changed}
    end
    @unresolved_refs
  end

  # Returns the overall unresolved references after trying to resolve references
  #
  def unresolved_refs
    return @unresolved_refs if @unresolved_refs
    resolve
  end

  # Returns the overall index. 
  # This is a Hash mapping identifiers to model elements accessible via the identifier. 
  #
  def index
    return @index if @index
    @index = {}
    fragments.each do |f|
      f.index.each do |i| 
        (@index[i[0]] ||= []) << i[1]
      end
    end
    @index
  end

  # Returns the overall reverse index.
  # This is a Hash mapping elements to their identifier.
  #
  def reverse_index
    return @reverse_index if @reverse_index
    @reverse_index = {}
    index.each_pair do |ident, elements|
      elements.each do |e|
        @reverse_index[e] = ident
      end
    end
    @reverse_index
  end

  private

  def invalidate_cache
    @index = nil
    @reverse_index = nil
    @unresolved_refs = nil
  end

  def invalidate_urefs
    @unresolved_refs = nil
  end

end

end

end
