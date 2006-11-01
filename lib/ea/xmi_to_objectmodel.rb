require 'rgen/transformer'
require 'ea/xmi_helper'
require 'ea/xmi_metamodel'
require 'uml/uml_objectmodel'
require 'rgen/array_extensions'

# This class is a RGen::Transformer working on an input and output Environment.
# It creates an UMLObjectModel from an XMI Model instantiated by a
# RGen::XMLInstantiator.
# 
# See description of RGen::XMLInstantiator for details about the XMI (meta-)model.
# See UMLObjectModel for details about the UML Object (meta-)model.
class XmiToObjectmodel < RGen::Transformer
	include UMLObjectModel
	include RGen::XMIHelper
	
	# Do the actual transformation.
	# Input and output environment have to be provided to the transformer constructor.
	def transform
		trans(
			@env_in.find(:class => XMIMetaModel::UML::ClassifierRole)-
			@env_in.find(:class => XMIMetaModel::UML::Clazz)
		)
	end

	transform XMIMetaModel::UML::Package, :to => UMLPackage do
		{ :name => name,
			:superpackage => trans(parent.parent.is_a?(XMIMetaModel::UML::Package) ? parent.parent : nil) }
	end
	
	transform XMIMetaModel::UML::ClassifierRole, :to => UMLObject, :if => :isEASTypeObject do 
	 	trans(associationEndRoles.parent.parent)
	 	trans(associationEnds.parent.parent)
	 	taggedValues = TaggedValueHelper.new(@current_object)
	 	{ :name => name,
	 	  :classname => taggedValues['classname'],
	 	  :attributeSettings => createAttributeSettings(taggedValues['runstate']),
	 	  :package => trans(parent.parent.parent.parent) }
	end
	
	method :isEASTypeObject do
	 	taggedValues = TaggedValueHelper.new(@current_object)
	 	taggedValues['ea_stype'] == 'Object'
	end
	
	def createAttributeSettings(runstate)
		return [] unless runstate
		result = []
		as = nil
		runstate.split(';').each do |t|
			if t == '@VAR'
				as = @env_out.new UMLAttributeSetting
				result << as
			elsif t =~ /(\w+)=(\w+)/
				as.name = $2 if $1 == 'Variable'
				as.value = $2 if $1 == 'Value'
			end
		end
		result
	end
	
	transform XMIMetaModel::UML::AssociationRole, :to => UMLAssociation, :if => :isEATypeAssociation do
		ends = association_connection.associationEndRole
		{ :endA => trans(ends[0]), :endB => trans(ends[1])}
	end
	
	method :isEATypeAssociation do
	 	taggedValues = TaggedValueHelper.new(@current_object)
		taggedValues['ea_type'] == 'Association'
	end

	transform XMIMetaModel::UML::Association, :to => UMLAggregation do
		ends = association_connection.associationEnd
		{ :endA => trans(ends[0]), :endB => trans(ends[1])}
	end
		
	transform XMIMetaModel::UML::AssociationEndRole, :to => UMLAssociationEnd do
		buildAssociationEnd
	end
	
	transform XMIMetaModel::UML::AssociationEnd, :to => UMLAssociationEnd do
		buildAssociationEnd
	end
	
	method :buildAssociationEnd do
		{ :object => trans(typeClass),
		  :role => name,
		  :composite => (aggregation == 'composite'),
		  :navigable => (isNavigable == 'true') }
	end
	
end
