require 'metamodels/uml13_metamodel'
require 'rgen/transformer'
require 'rgen/ecore/ecore'
require 'rgen/array_extensions'

class UML13ToECore < RGen::Transformer
	include RGen::ECore

	def transform
		trans(:class => UML13::Class)
	end

	transform UML13::Model, :to => EPackage do
	    trans(ownedClassOrPackage)
		{ :name => name && name.strip }
	end
		
	transform UML13::Package, :to => EPackage do
	    trans(ownedClassOrPackage)
		{ :name => name && name.strip, 
		  :eSuperPackage => trans(namespace.is_a?(UML13::Package) ? namespace : nil) }
	end
	
	method :ownedClassOrPackage do
	 ownedElement.select{|e| e.is_a?(UML13::Package) || e.is_a?(UML13::Class)}
	end
	
	transform UML13::Class, :to => EClass do
		{ :name => name && name.strip,
			:ePackage => trans(namespace.is_a?(UML13::Package) ? namespace : nil),
			:eStructuralFeatures => trans(feature.select{|f| f.is_a?(UML13::Attribute)} + associationEnd),
			:eOperations => trans(feature.select{|f| f.is_a?(UML13::Operation)}),
			:eSuperTypes =>  trans(generalization.parent + clientDependency.select{|d| d.stereotype.name == "implements"}.supplier),
      :eAnnotations => createAnnotations(taggedValue) }
	end

	transform UML13::Interface, :to => EClass do
		{ :name => name && name.strip,
			:ePackage => trans(namespace.is_a?(UML13::Package) ? namespace : nil),
			:eStructuralFeatures => trans(feature.select{|f| f.is_a?(UML13::Attribute)} + associationEnd),
			:eOperations => trans(feature.select{|f| f.is_a?(UML13::Operation)}),
			:eSuperTypes =>  trans(generalization.parent)}
	end

	transform UML13::Attribute, :to => EAttribute do
		typemap = { "string" => EString, "boolean" => EBoolean, "int" => EInt, "float" => EFloat }
		{	:name => name && name.strip, :eType => getType && typemap[getType.name && getType.name.downcase],
      :eAnnotations => createAnnotations(taggedValue) }
	end
	
	transform UML13::Operation, :to => EOperation do
		{ :name => name && name.strip }
	end
	
	transform UML13::AssociationEnd, :to => EReference, :if => :isReference do
	    otherEnd = association.connection.find{|ae| ae != @current_object}
		{ :eType => trans(otherEnd.type),
			:name => otherEnd.name && otherEnd.name.strip,
			:eOpposite => trans(otherEnd),
			:lowerBound => (otherEnd.multiplicity && otherEnd.multiplicity.range.first.lower &&
        otherEnd.multiplicity.range.first.lower.to_i) || 0,
			:upperBound => (otherEnd.multiplicity && otherEnd.multiplicity.range.first.upper && 
        otherEnd.multiplicity.range.first.upper.gsub('*','-1').to_i) || 1,
			:containment => (aggregation == :composite),
      :eAnnotations => createAnnotations(association.taggedValue) }
	end
	
	method :isReference do
	  otherEnd = association.connection.find{|ae| ae != @current_object}
      otherEnd.name && otherEnd.name.size > 0
	end			
  
  def createAnnotations(taggedValues)
    if taggedValues.size > 0
      [ EAnnotation.new(:details => trans(taggedValues)) ]
    else
      []
    end
  end

	transform UML13::TaggedValue, :to => EStringToStringMapEntry do
	 { :key => tag, :value => value}
	end
end