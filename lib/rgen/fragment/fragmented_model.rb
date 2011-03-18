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

  # Creates a fragmented model. Options:
  #
  #  :env: 
  #    environment which will be updated as model elements are added and removed
  #
  #  :reference_selector:
  #    is used to descide which part of a bidirectional reference will be replaced 
  #    by an unresolved reference when a fragment is removed
  #    _required_ when fragments are to be removed, see ModelFragment#unresolve
  #
  def initialize(options={})
    @env = options[:env]
    @reference_selector = options[:reference_selector]
    @fragments = []
    @index = nil
    @unresolved_refs = nil
  end

  # Add a fragment.
  #
  def add_fragment(fragment)
    invalidate_cache
    @fragments << fragment
    fragment.elements.each{|e| @env << e} if @env
  end

  # Removes the fragment. The fragment will be unresolved using unresolve_fragment.
  #
  def remove_fragment(fragment)
    raise "fragment not part of model" unless @fragments.include?(fragment)
    invalidate_cache
    @fragments.delete(fragment)
    unresolve_fragment(fragment)
    fragment.elements.each{|e| @env.delete(e)} if @env
  end

  # Remove all references between this fragment and all other fragments.
  # The references will be replaced with unresolved references (MMProxy objects).
  # For bidirectional references, the reference selector provided to the constructor
  # defines for which reference and unresolved reference and proxy will be created
  #
  def unresolve_fragment(fragment)
    raise "unresolve fragment without a reference selector" unless @reference_selector
    invalidate_urefs
    fragment.unresolve(@reference_selector)
    @fragments.each do |f| 
      f.refs_changed if f != fragment
    end
  end

  # Resolve references between fragments. 
  # It is assumed that references within fragments have already been resolved.
  # This method can be called several times. 
  # It will updated the overall unresolved references.
  #
  def resolve
    urefs = []
    @fragments.each{|f| urefs.concat(f.unresolved_refs)}
    resolver = RGen::Instantiator::Resolver.new(
      :identifier_resolver => proc do |ident|
        index[ident]
      end)
    @unresolved_refs = resolver.resolve(urefs)
    @fragments.each{|f| f.refs_changed}
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

  private

  def invalidate_cache
    @index = nil
    @unresolved_refs = nil
  end

  def invalidate_urefs
    @unresolved_refs = nil
  end

end

end

end
