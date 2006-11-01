require 'rgen/transformer'
require 'ea/xmi_helper'
require 'ea/xmi_metamodel'
require 'uml/uml_classmodel'
require 'rgen/array_extensions'

# This class is a RGen::Transformer working on an input and output Environment.
# It creates an UMLClassModel from an XMI Model instantiated by a
# RGen::XMLInstantiator.
# 
# See description of RGen::XMLInstantiator for details about the XMI (meta-)model.
# See UMLClassModel for details about the UML Class (meta-)model.
class XmiToClassmodel < RGen::Transformer
	include UMLClassModel
	include RGen::XMIHelper

	# Do the actual transformation.
	# Input and output environment have to be provided to the transformer constructor.
	def transform
		trans(:class => XMIMetaModel::UML::Clazz)
	end
	
	transform XMIMetaModel::UML::Package, :to => UMLPackage do
		{ :name => name, 
			:superpackage => trans(parent.parent.is_a?(XMIMetaModel::UML::Package) ? parent.parent : nil) }
	end
	
	transform XMIMetaModel::UML::Attribute, :to => UMLAttribute do
		tv = TaggedValueHelper.new(@current_object)
		{	:name => name, :type => tv['type'] }
	end
	
	transform XMIMetaModel::UML::Operation, :to => UMLOperation do
		{ :name => name }
	end
	
	transform XMIMetaModel::UML::TaggedValue, :to => UMLTaggedValue do
		{ :tag => tag, :value => value }
	end
	
	transform XMIMetaModel::UML::Clazz, :to => UMLClass do
		{ :name => name,
			:package => trans(parent.parent.is_a?(XMIMetaModel::UML::Package) ? parent.parent : nil),
			:attributes => trans(classifier_feature.attribute),
			:operations => trans(classifier_feature.operation),
			:taggedvalues => trans(modelElement_taggedValue.taggedValue),
			:stereotypes => modelElement_stereotype.stereotype.name,
			:subclasses =>  trans(generalizationsAsSupertype.subtypeClass),
			:assocEnds => trans(associationEnds)}
	end
	
	transform XMIMetaModel::UML::Association, :to => :scAssociationClass do
		{ :endA => trans(scAssocEnds[0]),
			:endB => trans(scAssocEnds[1]) }
	end	
	
	method :scAssocEnds do
		association_connection.associationEnd
	end
	
	method :scAssociationClass do
		(scAssocEnds[0].aggregation == 'composite' or 
		 scAssocEnds[1].aggregation == 'composite' ?
		 UMLAggregation : UMLAssociation )
	end
	
	transform XMIMetaModel::UML::AssociationEnd, :to => UMLAssociationEnd do
		# since we don't want to figure out if we are end A or end B,
		# we let the association transformer do the work
		trans(parent.parent)
		{ :clazz => trans(typeClass),
			:role => name,
			:multiplicity => multiplicity,
			:composite => (aggregation == 'composite'),
			:navigable => (isNavigable == 'true')	}
	end
				
end