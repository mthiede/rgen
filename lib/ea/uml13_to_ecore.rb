require 'rgen/transformer'
require 'metamodels/uml13_metamodel'
require 'rgen/ecore/ecore'
require 'rgen/array_extensions'

class UML13ToECore < RGen::Transformer
	include RGen::ECore

	def transform
		trans(:class => UML13::Class)
	end

	transform UML13::Model, :to => EPackage do
	    trans(ownedClassOrPackage)
		{ :name => name }
	end
		
	transform UML13::Package, :to => EPackage do
	    trans(ownedClassOrPackage)
		{ :name => name, 
		  :eSuperPackage => trans(namespace.is_a?(UML13::Package) ? namespace : nil) }
	end
	
	method :ownedClassOrPackage do
	 ownedElement.select{|e| e.is_a?(UML13::Package) || e.is_a?(UML13::Class)}
	end
	
	transform UML13::Class, :to => EClass do
		{ :name => name,
			:ePackage => trans(namespace.is_a?(UML13::Package) ? namespace : nil),
			:eStructuralFeatures => trans(feature.select{|f| f.is_a?(UML13::Attribute)} + associationEnd),
			:eOperations => trans(feature.select{|f| f.is_a?(UML13::Operation)}),
			:eSuperTypes =>  trans(generalization.parent)}
	end

	transform UML13::Interface, :to => EClass do
		{ :name => name,
			:ePackage => trans(namespace.is_a?(UML13::Package) ? namespace : nil),
			:eStructuralFeatures => trans(feature.select{|f| f.is_a?(UML13::Attribute)} + associationEnd),
			:eOperations => trans(feature.select{|f| f.is_a?(UML13::Operation)}),
			:eSuperTypes =>  trans(generalization.parent)}
	end

	transform UML13::Attribute, :to => EAttribute do
		typemap = { "string" => EString, "boolean" => EBoolean, "int" => EInt, "float" => EFloat }
		typetv = taggedValue.find{|tv| tv.tag == "type"}
		{	:name => name, :eType => (typetv && typetv.value && typemap[typetv.value.downcase]) }
	end
	
	transform UML13::Operation, :to => EOperation do
		{ :name => name }
	end
	
	transform UML13::AssociationEnd, :to => EReference, :if => :isReference do
	    otherEnd = association.connection.find{|ae| ae != @current_object}
		{ :eType => trans(otherEnd.type),
			:name => otherEnd.name,
			:eOpposite => trans(otherEnd),
			:lowerBound => otherEnd.multiplicity ? otherEnd.multiplicity.range.first.lower.to_i : 0,
			:upperBound => otherEnd.multiplicity ? otherEnd.multiplicity.range.first.upper.gsub('*','-1').to_i : 1,
			:containment => (aggregation == :composite) }
	end
	
	method :isReference do
	  otherEnd = association.connection.find{|ae| ae != @current_object}
      otherEnd.isNavigable || 
	  # composite assocations are bidirectional
	  aggregation == :composite || otherEnd.aggregation == :composite
	end			
end