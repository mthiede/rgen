require 'rgen/instantiator/qualified_name_resolver'
require 'concrete_support/json_parser'

module ConcreteSupport

class JsonInstantiator

  def initialize(env, mm, options={})
    @env = env
    @mm = mm
    @options = options
    @unresolvedReferences = []
    @parser = JsonParser.new(self)
  end

  def instantiate(str)
    root = @parser.parse(str)
    resolver = RGen::Instantiator::QualifiedNameResolver.new(root, @options)
    resolver.resolveReferences(@unresolvedReferences)
  end

  def createObject(hash)
    className = hash["_class"]
    raise "no class information" unless className
    clazz = @mm.const_get(className)
    raise "class not found: #{className}" unless clazz
    hash.delete("_class")
    urefs = []
    hash.keys.each do |k|
      f = eFeature(k, clazz)
      hash[k] = [hash[k]] if f.many && !hash[k].is_a?(Array)
      if f.is_a?(RGen::ECore::EReference) && !f.containment
        if f.many
          idents = hash[k]
          hash[k] = idents.collect do |i|
            proxy = RGen::MetamodelBuilder::MMProxy.new(i)
            urefs << RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(nil, k, proxy)
            proxy
          end
        else
          ident = hash[k]
          ident = ident.first if ident.is_a?(Array)
          proxy = RGen::MetamodelBuilder::MMProxy.new(ident)
          hash[k] = proxy
          urefs << RGen::Instantiator::ReferenceResolver::UnresolvedReference.new(nil, k, proxy)
        end
      elsif f.eType.is_a?(RGen::ECore::EEnum)
        hash[k] = hash[k].to_sym
      elsif f.eType.instanceClassName == "Float"
        hash[k] = hash[k].to_f
      end
    end  
    obj = @env.new(clazz, hash)
    urefs.each do |r|
      r.element = obj
      @unresolvedReferences << r 
    end
    obj
  end

  private
  
  def eFeature(name, clazz) 
    @eFeature ||= {}
    @eFeature[clazz] ||= {}
    @eFeature[clazz][name] ||= clazz.ecore.eAllStructuralFeatures.find{|f| f.name == name}
  end
  
end

end
