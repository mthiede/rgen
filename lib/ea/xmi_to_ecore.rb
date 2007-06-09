require 'rgen/transformer'
require 'ea/xmi_helper'
require 'ea/xmi_metamodel'
require 'rgen/ecore/ecore'
require 'rgen/array_extensions'

# This class is a RGen::Transformer working on an input and output Environment.
# It creates an ECore based metamodel from an XMI Model instantiated by a
# RGen::Instantiator::DefaultXMLInstantiator.
# 
# See description of RGen::Instantiator::DefaultXMLInstantiator for details about the XMI (meta-)model.
# See RGen::ECore for details about the Ecore metamodel.
class XmiToECore < RGen::Transformer
	include RGen::ECore
	include RGen::XMIHelper

	# Do the actual transformation.
	# Input and output environment have to be provided to the transformer constructor.
	def transform
		trans(:class => XMIMetaModel::UML::Clazz)
	end
	
	transform XMIMetaModel::UML::Package, :to => EPackage do
		{ :name => name, 
			:eSuperPackage => trans(parent.parent.is_a?(XMIMetaModel::UML::Package) ? parent.parent : nil) }
	end
	
	transform XMIMetaModel::UML::Clazz, :to => EClass do
		{ :name => name,
			:ePackage => trans(parent.parent.is_a?(XMIMetaModel::UML::Package) ? parent.parent : nil),
			:eStructuralFeatures => trans(classifier_feature.attribute + associationEnds),
			:eOperations => trans(classifier_feature.operation),
			:eSuperTypes =>  trans(generalizationsAsSubtype.supertypeClass)}
	end

	transform XMIMetaModel::UML::Attribute, :to => EAttribute do
		typemap = { "String" => EString, "boolean" => EBoolean, "int" => EInt, "float" => EFloat }
		tv = TaggedValueHelper.new(@current_object)
		{	:name => name, :eType => typemap[tv['type']] }
	end
	
	transform XMIMetaModel::UML::Operation, :to => EOperation do
		{ :name => name }
	end
	
	transform XMIMetaModel::UML::AssociationEnd, :to => EReference, :if => :isReference do
		{ :eType => trans(otherEnd.typeClass),
			:name => otherEnd.name,
			:eOpposite => trans(otherEnd),
			:lowerBound => (otherEnd.multiplicity || '0').split('..').first.to_i,
			:upperBound => (otherEnd.multiplicity || '1').split('..').last.gsub('*','-1').to_i,
			:containment => (aggregation == 'composite') }
	end
	
	method :isReference do
      otherEnd.isNavigable == 'true' || 
	  # composite assocations are bidirectional
	  aggregation == 'composite' || otherEnd.aggregation == 'composite'
	end			
end