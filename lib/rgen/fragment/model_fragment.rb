require 'rgen/instantiator/reference_resolver'

module RGen

module Fragment

# A model fragment is a list of root model elements associated with a location (e.g. a file)
#
# Optionally, an arbitrary data object may be associated with the fragment. The data object
# will be stored in the cache. Subclasses of Fragment may use the data object to associate
# more data, e.g. by providing a Hash.
#
# If an element within the fragment changes or if the fragement is connected or disconnected 
# this must be indicated to the fragment by calling +changed+ or +refs_changed+ respectively.
#
class ModelFragment
  attr_reader :root_elements
  attr_reader :index
  attr_accessor :location, :data
  
  # Create a model fragment
  #
  #  :data:
  #    data object associated with this fragment
  #
  def initialize(location, options={})
    @location = location
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
      ident = identifier_provider && identifier_provider.call(e)
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
  # be sure to call +refs_changed+ on all fragments connected as their references may
  # change to unresolved references
  #
  # TODO: make sure reference order is preserved
  def unresolve(reference_selector)
    @unresolved_refs = []
    elements_hash = {}
    elements.each{|e| elements_hash[e] = true}
    elements.each do |e|
      each_reference_target(e) do |r, t|
        if t.is_a?(RGen::MetamodelBuilder::MMProxy)
          @unresolved_refs << 
            RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(e, r.name, t)
        elsif !elements_hash[t]
          if r.many?
            e.removeGeneric(r.name, t)
          else
            e.setGeneric(r.name, nil)
          end
          if !r.eOpposite || reference_selector.call(r)
            proxy = RGen::MetamodelBuilder::MMProxy.new(t.qualifiedName, t.class.ecore.name)
            e.setOrAddGeneric(r.name, proxy)
            @unresolved_refs << 
              RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(e, r.name, proxy)
          else
            proxy = RGen::MetamodelBuilder::MMProxy.new(e.qualifiedName, e.class.ecore.name)
            t.setOrAddGeneric(r.eOpposite.name, proxy)
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


