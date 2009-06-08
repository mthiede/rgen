require 'rgen/ecore/ecore_ext'

module RGen

module ModelBuilder

class BuilderContext
  attr_accessor :contextElement, :resolver
end

class ReferenceResolver
  ResolverJob = Struct.new(:receiver, :reference, :namespace, :string)
  
  class ResolverException < Exception
  end

  def addJob(job)
    @jobs ||= []
    @jobs << job
  end
  
  def resolve(env=nil)
    (@jobs || []).each do |job|
      begin
        target = resolveReference(env, job.namespace, job.string.split("."), job.reference.eType.instanceClass, true)
      rescue ResolverException => e
        raise ResolverException.new("Can not resolve reference #{job.string}: #{e.message}")
      end
      if job.reference.many
        job.receiver.addGeneric(job.reference.name, target)
      else
        job.receiver.setGeneric(job.reference.name, target)
      end
    end
  end
  
  private
  
  def resolveReference(env, namespace, nameParts, targetClass, toplevel=false)
    #puts "resolveReferences nameParts " + nameParts.inspect + " namespace #{namespace}"
    firstPart, *restParts = nameParts
    if namespace
      children = elementChildren(namespace)
      #puts children.inspect
      #puts "looking for a element named #{firstPart}"
      elements = children.select{|e| e.respond_to?(:name) && e.name == firstPart}
      #puts elements.inspect
      #puts elementParents(namespace).inspect
      if elements.empty? && elementParents(namespace).size > 0 && toplevel
        #puts "Trying parent"
        raise ResolverException.new("Element #{namespace} has multiple parents") if elementParents(namespace).size > 1
        elements << resolveReference(env, elementParents(namespace).first, nameParts, targetClass, true)
      else
        where = "within children of #{namespace}"
        where += " named #{namespace.name}" if namespace.respond_to?(:name)
      end
    elsif env
      elements = env.find(:class => targetClass, :name => firstPart)
      where = "in environment"
    else
      raise ResolverException.new("Neither namespace nor environment specified")
    end
    raise ResolverException.new("Can not find element named #{firstPart} #{where}") if elements.size == 0
    raise ResolverException.new("Multiple elements named #{firstPart} found #{where}") if elements.size > 1
    if restParts.size > 0
      resolveReference(env, elements.first, restParts, targetClass)
    else
      elements.first
    end
  end
  
  def elementChildren(element)
    @elementChildren ||= {}
    return @elementChildren[element] if @elementChildren[element]
    children = element.class.ecore.eAllReferences.select{|r| r.containment}.collect do |r|
      element.getGeneric(r.name)
    end.flatten.compact
    @elementChildren[element] = children
  end
  
  def elementParents(element)
    @elementParents ||= {}
    return @elementParents[element] if @elementParents[element]
    parents = element.class.ecore.eAllReferences.select{|r| r.eOpposite && r.eOpposite.containment}.collect do |r|
      element.getGeneric(r.name)
    end.flatten.compact
    @elementParents[element] = parents
  end  
end

# this module takes up helper methods to avoid littering the package modules
module Helper
  class << self
    def processArguments(args)
      unless (args.size == 2 && args.first.is_a?(String) && args.last.is_a?(Hash)) ||
        (args.size == 1 && (args.first.is_a?(String) || args.first.is_a?(Hash)))
        raise "Provide a Hash to set feature values, " +
          "optionally the first argument may be a String specifying " + 
          "the value of the \"name\" attribute."
      end
      if args.last.is_a?(Hash)
        argHash = args.last
      else
        argHash = {}
      end
      argHash[:name] ||= args.first if args.first.is_a?(String)
      argHash
    end
    
    def processArgHash(argHash, eClass)
      resolverJobs = []
      asRole = nil
      argHash.each_pair do |k,v|
        if k == :as
          asRole = v
          argHash.delete(k)
        elsif v.is_a?(String)
          ref = eClass.eAllReferences.find{|r| r.name == k.to_s}
          if ref
            argHash.delete(k)
            resolverJobs << ReferenceResolver::ResolverJob.new(nil, ref, nil,  v)
          end
        end
      end
      [ resolverJobs, asRole ]
    end
    
    def associateWithContextElement(element, contextElement, asRole)
      return unless contextElement
      contextClass = contextElement.class.ecore
      if asRole
        asRoleRef = contextClass.eAllReferences.find{|r| r.name == asRole.to_s}
        raise "Context class #{contextClass.name} has no reference named #{asRole}" unless asRoleRef
        ref = asRoleRef
      else
        possibleContainmentRefs = contextClass.eAllReferences.select { |r| r.containment && 
          (element.class.ecore.eAllSuperTypes << element.class.ecore).include?(r.eType) }
        if possibleContainmentRefs.size == 1
          ref = possibleContainmentRefs.first
        elsif possibleContainmentRefs.size == 0
          raise "Context class #{contextClass.name} can not contain a #{element.class.ecore.name}"
        else
          raise "Context class #{contextClass.name} has several containment references to a #{element.class.ecore.name}." +
            " Clearify using \":as => <role>\""
        end
      end
      if ref.many
        contextElement.addGeneric(ref.name, element)
      else
        contextElement.setGeneric(ref.name, element)
      end
    end
  end
end

end

module MetamodelBuilder

module ModuleExtension

  def method_missing(m, *args, &block)
    return super unless self.ecore.is_a?(RGen::ECore::EPackage)
    className = m.to_s[0..0].upcase + m.to_s[1..-1]
    eClass = self.ecore.eClasses.find{|c| c.name == className}
    return super unless eClass
    argHash = ModelBuilder::Helper.processArguments(args)
    resolverJobs, asRole = ModelBuilder::Helper.processArgHash(argHash, eClass)
    element = eClass.instanceClass.new(argHash)
    if @builderContext
      ModelBuilder::Helper.associateWithContextElement(element, @builderContext.contextElement, asRole)
      resolver = @builderContext.resolver 
    else
      resolver = ModelBuilder::ReferenceResolver.new
    end
    resolverJobs.each do |job|
      job.receiver = element
      job.namespace = @builderContext && @builderContext.contextElement
      resolver.addJob(job)
    end
    # process block
    if block
      if @builderContext
        @builderContext, oldContext = @builderContext.dup, @builderContext
      else
        @builderContext = ModelBuilder::BuilderContext.new
        @builderContext.resolver = resolver
        oldContext = nil
      end
      @builderContext.contextElement = element
      instance_eval(&block)
      @builderContext = oldContext
      if oldContext.nil?
        # we are back on toplevel
        resolver.resolve
      end
    end
    element
  end
  
end

end

end
