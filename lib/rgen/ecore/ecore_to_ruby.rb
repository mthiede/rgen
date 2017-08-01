require 'set'
require 'rgen/ecore/ecore'

module RGen
  
module ECore

# ECoreToRuby can turn ECore models into their Ruby metamodel representations
class ECoreToRuby
  
  def initialize
    @modules = {}
    @classifiers = {}
    @features_added = {}
    @reserved = Set.new(Object.methods)
  end

  # Create a Ruby module representing +epackage+.
  # This includes all nested modules/packages, classes and enums.
  #
  # If a parent module is provided with the "under" parameter, 
  # the new module will be nested under the parent module.
  #
  # If the parent module has a non-temporary name,
  # (more precisely: a non-temporary classpath) i.e. if it is reachable
  # via a path of constant names from the root, then the nested
  # modules and classes will also have non-temporary names.
  # In particular, this means that they will keep their names even
  # if they are assigned to new constants.
  # 
  # If no parent module is provided or the parent module has a
  # temporary name by itself, then the nested modules and classes will
  # also have temporary names. This means that their name will stay
  # 'volatile' until they are assigned to constants reachable from
  # the root and the Module#name method is called for the first time.
  #
  # While the second approach is more flexible, it can come with a major
  # performance impact. The reason is that Ruby searches the space of
  # all known non-temporary classes/modules every time the name
  # of a class/module with a temporary name is queried.
  #
  def create_module(epackage, under=Module.new)
    with_empty_constant_order_helper do
      temp = under.to_s.start_with?("#")
      mod = create_module_internal(epackage, under, temp)

      epackage.eAllClassifiers.each do |c| 
        if c.is_a?(RGen::ECore::EClass)
          create_class(c, temp)
        elsif c.is_a?(RGen::ECore::EEnum)
          create_enum(c)
        end
      end

      load_classes_with_reserved_keywords(epackage)
      mod
    end
  end

  private

  def load_classes_with_reserved_keywords(epackage)
    epackage.eAllClassifiers.each do |eclass|
      # we early load classes which have ruby reserved keywords
      if eclass.is_a?(RGen::ECore::EClass)
        reserved_used = eclass.eStructuralFeatures.any? { |f| @reserved.include?(f.name.to_sym) }
        add_features(eclass) if reserved_used
      end
    end
  end

  def create_module_internal(epackage, under, temp)
    return @modules[epackage] if @modules[epackage]
    
    if temp
      mod = Module.new do
        extend RGen::MetamodelBuilder::ModuleExtension
      end
      under.const_set(epackage.name, mod)
    else
      under.module_eval <<-END
        module #{epackage.name}
          extend RGen::MetamodelBuilder::ModuleExtension
        end
      END
      mod = under.const_get(epackage.name)
    end
    @modules[epackage] = mod

    epackage.eSubpackages.each{|p| create_module_internal(p, mod, temp)}
    mod._set_ecore_internal(epackage)

    mod
  end

  def create_class(eclass, temp)
    return @classifiers[eclass] if @classifiers[eclass]

    mod = @modules[eclass.ePackage]
    if temp
      cls = Class.new(super_class(eclass, temp)) do
        abstract if eclass.abstract
        class << self
          attr_accessor :_ecore_to_ruby
         end
      end
      mod.const_set(eclass.name, cls)
    else
      mod.module_eval <<-END
        class #{eclass.name} < #{super_class(eclass, temp)}
          #{eclass.abstract ? 'abstract' : ''}
          class << self
            attr_accessor :_ecore_to_ruby
          end
        end
      END
      cls = mod.const_get(eclass.name)
    end

    class << eclass
      attr_accessor :instanceClass
      def instanceClassName
        instanceClass.to_s
      end
    end
    eclass.instanceClass = cls

    cls::ClassModule.module_eval do
      alias _method_missing method_missing
      def method_missing(m, *args)
        if self.class._ecore_to_ruby.add_features(self.class.ecore)
          send(m, *args)
        else
          _method_missing(m, *args)
        end
      end
      alias _respond_to respond_to?
      def respond_to?(m, include_all=false)
        self.class._ecore_to_ruby.add_features(self.class.ecore)
        _respond_to(m)
      end
    end
    @classifiers[eclass] = cls
    cls._set_ecore_internal(eclass)
    cls._ecore_to_ruby = self

    cls
  end

  def create_enum(eenum)
    return @classifiers[eenum] if @classifiers[eenum]

    e = RGen::MetamodelBuilder::DataTypes::Enum.new(eenum.eLiterals.collect{|l| l.name.to_sym})
    @classifiers[eenum] = e

    @modules[eenum.ePackage].const_set(eenum.name, e)
    e
  end

  class FeatureWrapper
    def initialize(efeature, classifiers)
      @efeature = efeature
      @classifiers = classifiers
    end
    def value(prop)
      return false if prop == :containment && @efeature.is_a?(RGen::ECore::EAttribute)
      @efeature.send(prop)
    end
    def many?
      @efeature.many
    end
    def reference?
      @efeature.is_a?(RGen::ECore::EReference)
    end
    def opposite
      @efeature.eOpposite
    end
    def impl_type
      etype = @efeature.eType
      if etype.is_a?(RGen::ECore::EClass) || etype.is_a?(RGen::ECore::EEnum)
        @classifiers[etype]
      else
        ic = etype.instanceClass
        if ic
          ic
        else
          raise "unknown type: #{etype.name}" 
        end
      end
    end
  end

  def super_class(eclass, temp)
    super_types = eclass.eSuperTypes
    if temp
      case super_types.size
      when 0
        RGen::MetamodelBuilder::MMBase
      when 1
        create_class(super_types.first, temp)
      else
        RGen::MetamodelBuilder::MMMultiple(*super_types.collect{|t| create_class(t, temp)})
      end
    else
      case super_types.size
      when 0
        "RGen::MetamodelBuilder::MMBase"
      when 1
        create_class(super_types.first, temp).name
      else
        "RGen::MetamodelBuilder::MMMultiple(" + 
          super_types.collect{|t| create_class(t, temp).name}.join(",") + ")"
      end
    end
  end

  class EmptyConstantOrderHelper
    def classCreated(c); end
    def moduleCreated(m); end
    def enumCreated(e); end
  end

  def with_empty_constant_order_helper
    orig_coh = RGen::MetamodelBuilder::ConstantOrderHelper
    RGen::MetamodelBuilder.instance_eval { remove_const(:ConstantOrderHelper) }
    RGen::MetamodelBuilder.const_set(:ConstantOrderHelper, EmptyConstantOrderHelper.new)

    begin
      result = yield
    ensure
      RGen::MetamodelBuilder.instance_eval { remove_const(:ConstantOrderHelper) }
      RGen::MetamodelBuilder.const_set(:ConstantOrderHelper, orig_coh)
    end

    result
  end

  public

  def add_features(eclass)
    return false if @features_added[eclass]
    c = @classifiers[eclass]
    eclass.eStructuralFeatures.each do |f|
      w1 = FeatureWrapper.new(f, @classifiers) 
      w2 = FeatureWrapper.new(f.eOpposite, @classifiers) if f.is_a?(RGen::ECore::EReference) && f.eOpposite
      c.module_eval do
        if w1.many?
          _build_many_methods(w1, w2)
        else
          _build_one_methods(w1, w2)
        end
      end
    end
    @features_added[eclass] = true
    eclass.eSuperTypes.each do |t|
      add_features(t)
    end
    true
  end

end

end

end

