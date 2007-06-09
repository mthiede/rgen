require 'rgen/metamodel_builder'

module RGen

module MetamodelBuilder

class MetamodelDescription

	attr_reader :etype, :impl_type
		
	def self.default_value(prop)
		checkProperty(prop)
		defaultValues[prop]
	end
	
	def self.has_default?(prop)
		checkProperty(prop)
		defaultValues.has_key?(prop)
	end
	
	def initialize(props)
		@props = props.dup
	end

	def value(prop)
		self.class.checkProperty(prop)
		@props[prop]
	end
	
	def annotations
	    @annotations ||= []
	end
	
	def many?
		value(:upperBound) > 1 || value(:upperBound) == -1
	end

protected
	
  def setupDefaults
    self.class.propertySet.each do |p| 
      @props[p] = self.class.default_value(p) unless @props.has_key?(p)   
    end
  end

  def checkAllPropertiesSet
    self.class.propertySet.each do |p| 
      raise StandardError.new("'#{p}' property not set") if !self.class.optionalProperties.include?(p) && @props[p].nil?
    end
  end
  
  def checkForInvalidProperties
    @props.keys.each do |p|
      raise StandardError.new("invalid property #{p}") unless self.class.propertySet.include?(p)
    end
  end

private

	def descendent?(clazz1, clazz2)
		return true if clazz1 == clazz2 || clazz1.superclass == clazz2
		return false if clazz1.superclass.nil?
		descendent?(clazz1.superclass, clazz2)
	end

	def self.checkProperty(prop)
		raise ArgumentError.new("Not a valid property: #{prop}") unless propertySet.include?(prop)
	end
		
	def to_s
		self.class.to_s + ": " +
			self.class.propertySet.collect{|p| "#{p}=>#{value(p)}"}.join(", ")
	end
	
	def self.propertySet
		[ :name ]
	end
	

	def self.optionalProperties
        []
	end

	def self.defaultValues
		{ }
	end
	
	def self.typeMap
		{ :EString => String,
			:EInt => Integer,
			:EFloat => Float,
			:EBoolean => RGen::MetamodelBuilder::DataTypes::Boolean,
		  :EJavaObject => Object,
		  :ERubyObject => Object,
		  :EJavaClass => Class,
		  :ERubyClass => Class }
	end
	
end

# DERIVED:	ordered = true, unique = false, lowerBound = 0/1, upperBound = 1
# DERIVED: when :derived : changeable= false, :volatile=true, transient=true
class AttributeDescription < MetamodelDescription

	def initialize(type, props)
		super(props)
		# type default
		type ||= :EString 
		setupType(type)
		# fixed values can not be changed by user
    setupDefaults
    checkForInvalidProperties
		if @props[:derived]
			@props[:changeable] = false
			@props[:volatile] = true
			@props[:transient] = true
		end		
    checkAllPropertiesSet
	end
	
private

	def setupType(type)
		if self.class.typeMap.keys.include?(type)
			@etype = type
			@impl_type = self.class.typeMap[type]
		elsif self.class.typeMap.invert.keys.include?(type)
			@etype = self.class.typeMap.invert[type]
			@impl_type = type
		elsif type.is_a?(RGen::MetamodelBuilder::DataTypes::Enum)
			@etype = :EEnumerable
			@impl_type = type
    else
  		raise ArgumentError.new("Type invalid: " + type.to_s)
    end
	end

	def self.propertySet
		super | [ 
			:ordered, 
		  :unique,
		  :changeable,
		  :volatile,
		  :transient,
		  :unsettable,
			:derived,
			:lowerBound,
			:upperBound,
			:defaultValueLiteral ]
	end
	
	def self.optionalProperties
		super | [ 
          :defaultValueLiteral
        ]
	end

	def self.defaultValues 
		super.merge(
		{ :ordered => true,
		  :unique => true,
		  :changeable => true,
		  :volatile => false,
		  :transient => false,
		  :unsettable => false,
		  :derived => false,
			:lowerBound => 0 })
	end
	
end

#  DERIVED default: lowerBound => 0/1 (required?), upperBound => 1/-1 (many?), containment (contains_xxx?), 
#  DERIVED: when :derived : changeable= false, :volatile=true, transient=true
class ReferenceDescription < MetamodelDescription
	attr_accessor :opposite
	
	def initialize(type, props)
		super(props)
		setupType(type)
    setupDefaults
    checkForInvalidProperties
		if @props[:derived]
			@props[:changeable] = false
			@props[:volatile] = true
			@props[:transient] = true
		end		
    checkAllPropertiesSet
	end

private

	def setupType(type)
		if type.is_a?(Class) && descendent?(type, RGen::MetamodelBuilder::MMBase)
			@etype = nil
			@impl_type = type
    else
  		raise ArgumentError.new("Type is not a MMBase: " + type.to_s)
    end
	end

	def self.propertySet
		super | [ 
			:ordered, 
		  :unique,
		  :changeable,
		  :volatile,
		  :transient,
		  :unsettable,
			:derived,
			:lowerBound,
			:upperBound,
			:resolveProxies,
			:containment ]
	end

	def self.defaultValues 
		super.merge({ 
			:ordered => true,
		  :unique => true,
		  :changeable => true,
		  :volatile => false,
		  :transient => false,
		  :unsettable => false,
		  :derived => false,
		  :lowerBound => 0,
		  :resolveProxies => true })
	end
end

end

end