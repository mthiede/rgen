require 'rgen/instantiator/reference_resolver'

module RGen

module Fragment

# A model fragment is a list of root model elements associated with a location (e.g. a file)
#
# Optionally, an arbitrary data object may be associated with the fragment. The data object
# will also be stored in the cache.
#
# If an element within the fragment changes or if the fragement is connected or disconnected 
# this must be indicated to the fragment by calling +changed+ or +refs_changed+ respectively.
# This will normally be taken care of by a FragmentedModel.
#
class ModelFragment
  attr_reader :root_elements
  attr_reader :index
  attr_accessor :location, :fragment_ref, :data
  
  # A FragmentRef serves as a single target object for elements which need to reference the
  # fragment they are contained in. The FragmentRef references the fragment it is contained in.
  # The FragmentRef is separate from the fragment itself, to allow storing it in a marshal dump
  # independently of the fragment.
  #
  class FragmentRef
    attr_accessor :fragment
  end

  # Create a model fragment
  #
  #  :data
  #    data object associated with this fragment
  #
  def initialize(location, options={})
    @location = location
    @fragment_ref = FragmentRef.new
    @fragment_ref.fragment = self
    @data = options[:data]
  end

  # Set the root elements, normally done by a instantiator.
  #
  # For optimization reasons the instantiator of the fragment may provide data explicitly which
  # is normally derived by the fragment itself. In this case it is essential that this
  # data is consistent with the fragment.
  #
  def set_root_elements(root_elements, options={})
    @root_elements = root_elements 
    @elements = options[:elements]
    @index = options[:index]
    @unresolved_refs = options[:unresolved_refs]
  end

  # must be called when any of the elements in this fragment has been changed
  def changed
    @elements = nil
    @index = nil
    @unresolved_refs = nil
  end

  # must be called when an unresolved references of this fragment has been resolved
  # or when a new unresolved reference has been added 
  def refs_changed
    @unresolved_refs = nil
  end

  # returns all elements within this fragment
  def elements
    return @elements if @elements
    @elements = []
    @root_elements.each do |e|
      all_child_elements(e, @elements)
    end
    @elements
  end

  # returns all unresolved references within this fragment, i.e. references to MMProxy objects
  def unresolved_refs
    return @unresolved_refs if @unresolved_refs
    @unresolved_refs = []
    elements.each do |e|
      each_reference_target(e) do |r, t|
        if t.is_a?(RGen::MetamodelBuilder::MMProxy)
          @unresolved_refs << 
            RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(e, r.name, t)
        end
      end
    end
    @unresolved_refs
  end

  # Builds the index of all elements within this fragment having an identifier
  # the index is an array of 2-element arrays holding the identifier and the element
  #
  # +identifier_provider+ must be a proc which receives a model element and must return 
  # that element's identifier or nil if the element has no identifier
  #
  def build_index(identifier_provider)
    @index = elements.collect { |e|
      ident = identifier_provider && identifier_provider.call(e, nil)
      ident && !ident.empty? ? [ident, e] : nil 
    }.compact
  end

  # disconnects elements within this fragment from elements outside of this fragment
  # by replacing references with MMProxy objects, i.e. unresolved references 
  #
  # +reference_selector+ is a proc which is called to descide for which part of a 
  # bidirectional reference a MMProxy object will be created;
  # the proc receives an EReference;
  # if it returns true, the MMProxy object will be created in the direction
  # of the EReference provided, otherwise it will be created for the opposite reference 
  #
  # +identifier_provider+ is a proc which is called with an element and should return
  # the identifier of that element
  #
  # +fragment_provider+ is a proc which is called with an element and should return the
  # fragment in which this element is contained in. if the fragment can not be retrieved
  # the proc may return null. the fragment information is required for updating the
  # unresolved references of that fragment. in case this information is not available for
  # one or more elements, +refs_changed+ must be called on all fragments which might be
  # affected
  #
  # TODO: make sure reference order is preserved
  def unresolve(reference_selector, identifier_provider, fragment_provider)
    @unresolved_refs = []
    elements_hash = {}
    elements.each{|e| elements_hash[e] = true}
    elements.each do |e|
      each_reference_target(e) do |r, t|
        if t.is_a?(RGen::MetamodelBuilder::MMProxy)
          @unresolved_refs << 
            RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(e, r.name, t)
        elsif !elements_hash[t]
          if r.many
            e.removeGeneric(r.name, t)
          else
            e.setGeneric(r.name, nil)
          end
          if !r.eOpposite || reference_selector.call(r)
            proxy = RGen::MetamodelBuilder::MMProxy.new(identifier_provider.call(t), t.class.ecore.name)
            e.setOrAddGeneric(r.name, proxy)
            @unresolved_refs << 
              RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(e, r.name, proxy)
          else
            proxy = RGen::MetamodelBuilder::MMProxy.new(identifier_provider.call(e), e.class.ecore.name)
            t.setOrAddGeneric(r.eOpposite.name, proxy)
            target_fragment = fragment_provider && fragment_provider.call(t)
            if target_fragment
              target_fragment.add_unresolved_ref(
                RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(t, r.eOpposite.name, proxy))
            end
          end
        end
      end
    end       
  end

  # resolves local references (within this fragment) as far as possible
  def resolve_local
    resolver = RGen::Instantiator::ReferenceResolver.new
    raise "index does not exist, call build_index first" unless index
    index.each do |i|
      resolver.add_identifier(i[0], i[1])
    end
    @unresolved_refs = resolver.resolve(unresolved_refs)
  end

  # remove unresolved references from the unresolved references cache
  # this method must be used with care, in order to keep the cache consistent
  #
  def remove_unresolved_refs(unresolved_refs)
    @unresolved_refs -= unresolved_refs
  end

  protected

  # add an unresolved reference to the unresolved references cache
  # this method must be used with care, in order to keep the cache consistent
  #
  def add_unresolved_ref(unresolved_ref)
    @unresolved_refs << unresolved_ref
  end

  private

  def each_reference_target(element)
    non_containment_references(element.class).each do |r|
      element.getGenericAsArray(r.name).each do |t|
        yield(r, t)
      end
    end
  end

  def all_child_elements(element, childs)
    containment_references(element.class).each do |r|
      element.getGenericAsArray(r.name).each do |c|
        childs << c
        all_child_elements(c, childs)
      end
    end
  end

  def containment_references(clazz)
    @@containment_references_cache ||= {}
    @@containment_references_cache[clazz] ||=
      clazz.ecore.eAllReferences.select{|r| r.containment}
  end

  def non_containment_references(clazz)
    @@non_containment_references_cache ||= {}
    @@non_containment_references_cache[clazz] ||= 
      clazz.ecore.eAllReferences.select{|r| !r.containment}
  end 

end

end

end


