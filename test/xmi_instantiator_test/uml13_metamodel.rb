require 'rgen/metamodel_builder'
module UML13
   extend RGen::ECore::ECoreInstantiator

   AggregationKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :none, :aggregate, :composite ])
   ChangeableKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :changeable, :frozen, :addOnly ])
   OperationDirectionKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ ])
   ParameterDirectionKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :in, :inout, :out, :return ])
   MessageDirectionKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ ])
   ScopeKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :instance, :classifier ])
   VisibilityKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :public, :protected, :private ])
   PseudostateKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :initial, :deepHistory, :shallowHistory, :join, :fork, :branch, :junction, :final ])
   CallConcurrencyKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :sequential, :guarded, :concurrent ])
   OrderingKind = RGen::MetamodelBuilder::DataTypes::Enum.new([ :unordered, :ordered, :sorted ])

   module Element
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
   end

   module ModelElement
      include Element
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'name', String
      has_attr 'visibility', UML13::VisibilityKind, :defaultValueLiteral => "public"
      has_attr 'isSpecification', Boolean
   end

   class Namespace < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   module GeneralizableElement
      include ModelElement
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isRoot', Boolean
      has_attr 'isLeaf', Boolean
      has_attr 'isAbstract', Boolean
   end

   class Classifier < RGen::MetamodelBuilder::MMBase
      include GeneralizableElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Class < Classifier
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isActive', Boolean
   end

   class DataType < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
   end

   module Feature
      include ModelElement
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'ownerScope', UML13::ScopeKind, :defaultValueLiteral => "instance"
   end

   module StructuralFeature
      include Feature
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'changeability', UML13::ChangeableKind, :defaultValueLiteral => "changeable"
      has_attr 'targetScope', UML13::ScopeKind, :defaultValueLiteral => "instance"
   end

   class AssociationEnd < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isNavigable', Boolean, :defaultValueLiteral => "false"
      has_attr 'ordering', UML13::OrderingKind, :defaultValueLiteral => "unordered"
      has_attr 'aggregation', UML13::AggregationKind, :defaultValueLiteral => "none"
      has_attr 'targetScope', UML13::ScopeKind, :defaultValueLiteral => "instance"
      has_attr 'changeability', UML13::ChangeableKind, :defaultValueLiteral => "changeable"
   end

   class Interface < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
   end

   class Constraint < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Relationship < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Association < Relationship
      include GeneralizableElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Attribute < RGen::MetamodelBuilder::MMBase
      include StructuralFeature
      include RGen::MetamodelBuilder::DataTypes
   end

   module BehavioralFeature
      include Feature
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isQuery', Boolean
   end

   class Operation < RGen::MetamodelBuilder::MMBase
      include BehavioralFeature
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'concurrency', UML13::CallConcurrencyKind, :defaultValueLiteral => "sequential"
      has_attr 'isRoot', Boolean
      has_attr 'isLeaf', Boolean
      has_attr 'isAbstract', Boolean
   end

   class Parameter < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'kind', UML13::ParameterDirectionKind, :defaultValueLiteral => "inout"
   end

   class Method < RGen::MetamodelBuilder::MMBase
      include BehavioralFeature
      include RGen::MetamodelBuilder::DataTypes
   end

   class Generalization < Relationship
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'discriminator', String
   end

   class AssociationClass < Association
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class Dependency < Relationship
      include RGen::MetamodelBuilder::DataTypes
   end

   class Abstraction < Dependency
      include RGen::MetamodelBuilder::DataTypes
   end

   module PresentationElement
      include Element
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
   end

   class Usage < Dependency
      include RGen::MetamodelBuilder::DataTypes
   end

   class Binding < Dependency
      include RGen::MetamodelBuilder::DataTypes
   end

   class Component < RGen::MetamodelBuilder::MMBase
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class Node < RGen::MetamodelBuilder::MMBase
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class Permission < Dependency
      include RGen::MetamodelBuilder::DataTypes
   end

   class Comment < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'body', String
   end

   class Flow < Relationship
      include RGen::MetamodelBuilder::DataTypes
   end

   class TemplateParameter < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
   end

   class ElementResidence < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'visibility', UML13::VisibilityKind, :defaultValueLiteral => "public"
   end

   class Multiplicity < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
   end

   class Expression < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'language', String
      has_attr 'body', String
   end

   class ObjectSetExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class TimeExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class BooleanExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class ActionExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class MultiplicityRange < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'lower', String
      has_attr 'upper', String
   end

   class Structure < DataType
      include RGen::MetamodelBuilder::DataTypes
   end

   class Primitive < DataType
      include RGen::MetamodelBuilder::DataTypes
   end

   class Enumeration < DataType
      include RGen::MetamodelBuilder::DataTypes
   end

   class EnumerationLiteral < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'name', String
   end

   class ProgrammingLanguageType < DataType
      include RGen::MetamodelBuilder::DataTypes
   end

   class IterationExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class TypeExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class ArgListsExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class MappingExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class ProcedureExpression < Expression
      include RGen::MetamodelBuilder::DataTypes
   end

   class Stereotype < RGen::MetamodelBuilder::MMBase
      include GeneralizableElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'icon', String
      has_attr 'baseClass', String
   end

   class TaggedValue < RGen::MetamodelBuilder::MMBase
      include Element
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'tag', String
      has_attr 'value', String
   end

   class UseCase < RGen::MetamodelBuilder::MMBase
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class Actor < RGen::MetamodelBuilder::MMBase
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class Instance < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class UseCaseInstance < Instance
      include RGen::MetamodelBuilder::DataTypes
   end

   class Extend < Relationship
      include RGen::MetamodelBuilder::DataTypes
   end

   class Include < Relationship
      include RGen::MetamodelBuilder::DataTypes
   end

   class ExtensionPoint < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'location', String
   end

   class StateMachine < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   module Event
      include ModelElement
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
   end

   module StateVertex
      include ModelElement
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
   end

   class State < RGen::MetamodelBuilder::MMBase
      include StateVertex
      include RGen::MetamodelBuilder::DataTypes
   end

   class TimeEvent < RGen::MetamodelBuilder::MMBase
      include Event
      include RGen::MetamodelBuilder::DataTypes
   end

   class CallEvent < RGen::MetamodelBuilder::MMBase
      include Event
      include RGen::MetamodelBuilder::DataTypes
   end

   class SignalEvent < RGen::MetamodelBuilder::MMBase
      include Event
      include RGen::MetamodelBuilder::DataTypes
   end

   class Transition < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class CompositeState < State
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isConcurrent', Boolean
   end

   class ChangeEvent < RGen::MetamodelBuilder::MMBase
      include Event
      include RGen::MetamodelBuilder::DataTypes
   end

   class Guard < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Pseudostate < RGen::MetamodelBuilder::MMBase
      include StateVertex
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'kind', UML13::PseudostateKind, :defaultValueLiteral => "initial"
   end

   class SimpleState < State
      include RGen::MetamodelBuilder::DataTypes
   end

   class SubmachineState < CompositeState
      include RGen::MetamodelBuilder::DataTypes
   end

   class SynchState < RGen::MetamodelBuilder::MMBase
      include StateVertex
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'bound', Integer
   end

   class StubState < RGen::MetamodelBuilder::MMBase
      include StateVertex
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'referenceState', String
   end

   class FinalState < State
      include RGen::MetamodelBuilder::DataTypes
   end

   class Collaboration < Namespace
      include GeneralizableElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class ClassifierRole < RGen::MetamodelBuilder::MMBase
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class AssociationRole < Association
      include RGen::MetamodelBuilder::DataTypes
   end

   class AssociationEndRole < AssociationEnd
      include RGen::MetamodelBuilder::DataTypes
   end

   class Message < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Interaction < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Signal < RGen::MetamodelBuilder::MMBase
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class Action < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isAsynchronous', Boolean
   end

   class CreateAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class DestroyAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class UninterpretedAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class AttributeLink < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Object < Instance
      include RGen::MetamodelBuilder::DataTypes
   end

   module Link
      include ModelElement
      extend RGen::MetamodelBuilder::BuilderExtensions
      include RGen::MetamodelBuilder::DataTypes
   end

   class LinkObject < Object
      include Link
      include RGen::MetamodelBuilder::DataTypes
   end

   class DataValue < Instance
      include RGen::MetamodelBuilder::DataTypes
   end

   class CallAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class SendAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class ActionSequence < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class Argument < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Reception < RGen::MetamodelBuilder::MMBase
      include BehavioralFeature
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isPolymorphic', Boolean
      has_attr 'specification', String
   end

   class LinkEnd < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Call < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
   end

   class ReturnAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class TerminateAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class Stimulus < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class ActionInstance < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
   end

   class Exception < Signal
      include RGen::MetamodelBuilder::DataTypes
   end

   class AssignmentAction < Action
      include RGen::MetamodelBuilder::DataTypes
   end

   class ComponentInstance < Instance
      include RGen::MetamodelBuilder::DataTypes
   end

   class NodeInstance < Instance
      include RGen::MetamodelBuilder::DataTypes
   end

   class ActivityGraph < StateMachine
      include RGen::MetamodelBuilder::DataTypes
   end

   class Partition < RGen::MetamodelBuilder::MMBase
      include ModelElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class SubactivityState < SubmachineState
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isDynamic', Boolean
   end

   class ActionState < SimpleState
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isDynamic', Boolean
   end

   class CallState < ActionState
      include RGen::MetamodelBuilder::DataTypes
   end

   class ObjectFlowState < SimpleState
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isSynch', Boolean
   end

   class ClassifierInState < RGen::MetamodelBuilder::MMBase
      
      include RGen::MetamodelBuilder::DataTypes
   end

   class Package < Namespace
      include GeneralizableElement
      include RGen::MetamodelBuilder::DataTypes
   end

   class Model < Package
      include RGen::MetamodelBuilder::DataTypes
   end

   class Subsystem < Package
      
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'isInstantiable', Boolean
   end

   class ElementImport < RGen::MetamodelBuilder::MMBase
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'visibility', UML13::VisibilityKind, :defaultValueLiteral => "public"
      has_attr 'alias', String
   end

   class DiagramElement < RGen::MetamodelBuilder::MMBase
      include PresentationElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'geometry', String
      has_attr 'style', String
   end

   class Diagram < RGen::MetamodelBuilder::MMBase
      include PresentationElement
      include RGen::MetamodelBuilder::DataTypes
      has_attr 'name', String
      has_attr 'toolName', String
      has_attr 'diagramType', String
      has_attr 'style', String
   end

end

UML13::Classifier.many_to_many 'participant', UML13::AssociationEnd, 'specification'
UML13::Classifier.one_to_many 'associationEnd', UML13::AssociationEnd, 'type'
UML13::Classifier.contains_many 'feature', UML13::Feature, 'owner'
UML13::StructuralFeature.contains_one_uni 'multiplicity', UML13::Multiplicity
UML13::StructuralFeature.has_one 'type', UML13::Classifier, :lowerBound => 1
UML13::Namespace.contains_many 'ownedElement', UML13::ModelElement, 'namespace'
UML13::AssociationEnd.contains_one_uni 'multiplicity', UML13::Multiplicity
UML13::AssociationEnd.contains_many 'qualifier', UML13::Attribute, 'associationEnd'
UML13::Association.contains_many 'connection', UML13::AssociationEnd, 'association', :lowerBound => 2
UML13::Constraint.contains_one_uni 'body', UML13::BooleanExpression
UML13::Constraint.many_to_many 'constrainedElement', UML13::ModelElement, 'constraint', :lowerBound => 1
UML13::GeneralizableElement.one_to_many 'specialization', UML13::Generalization, 'parent'
UML13::GeneralizableElement.one_to_many 'generalization', UML13::Generalization, 'child'
UML13::Attribute.contains_one_uni 'initialValue', UML13::Expression
UML13::Operation.one_to_many 'occurrence', UML13::CallEvent, 'operation'
UML13::Operation.one_to_many 'method', UML13::Method, 'specification'
UML13::Parameter.contains_one_uni 'defaultValue', UML13::Expression
UML13::Parameter.many_to_many 'state', UML13::ObjectFlowState, 'parameter'
UML13::Parameter.has_one 'type', UML13::Classifier, :lowerBound => 1
UML13::Method.contains_one_uni 'body', UML13::ProcedureExpression
UML13::BehavioralFeature.many_to_many 'raisedSignal', UML13::Signal, 'context'
UML13::BehavioralFeature.contains_many_uni 'parameter', UML13::Parameter
UML13::ModelElement.one_to_many 'behavior', UML13::StateMachine, 'context'
UML13::ModelElement.many_to_one 'stereotype', UML13::Stereotype, 'extendedElement'
UML13::ModelElement.one_to_many 'elementResidence', UML13::ElementResidence, 'resident'
UML13::ModelElement.many_to_many 'sourceFlow', UML13::Flow, 'source'
UML13::ModelElement.many_to_many 'targetFlow', UML13::Flow, 'target'
UML13::ModelElement.many_to_many 'presentation', UML13::PresentationElement, 'subject'
UML13::ModelElement.many_to_many 'supplierDependency', UML13::Dependency, 'supplier', :lowerBound => 1
UML13::ModelElement.contains_many 'taggedValue', UML13::TaggedValue, 'modelElement'
UML13::ModelElement.contains_many_uni 'templateParameter', UML13::TemplateParameter
UML13::ModelElement.many_to_many 'clientDependency', UML13::Dependency, 'client', :lowerBound => 1
UML13::ModelElement.many_to_many 'comment', UML13::Comment, 'annotatedElement'
UML13::ModelElement.one_to_many 'elementImport', UML13::ElementImport, 'modelElement'
UML13::Abstraction.contains_one_uni 'mapping', UML13::MappingExpression
UML13::Binding.has_many 'argument', UML13::ModelElement, :lowerBound => 1
UML13::Component.contains_many 'residentElement', UML13::ElementResidence, 'implementationLocation'
UML13::Component.many_to_many 'deploymentLocation', UML13::Node, 'resident'
UML13::TemplateParameter.has_one 'modelElement', UML13::ModelElement
UML13::TemplateParameter.has_one 'defaultElement', UML13::ModelElement
UML13::Multiplicity.contains_many_uni 'range', UML13::MultiplicityRange, :lowerBound => 1
UML13::Enumeration.contains_many_uni 'literal', UML13::EnumerationLiteral, :lowerBound => 1
UML13::ProgrammingLanguageType.contains_one_uni 'type', UML13::TypeExpression
UML13::Stereotype.has_many 'requiredTag', UML13::TaggedValue
UML13::UseCase.has_many 'extensionPoint', UML13::ExtensionPoint
UML13::UseCase.one_to_many 'include', UML13::Include, 'base'
UML13::UseCase.one_to_many 'extend', UML13::Extend, 'extension'
UML13::Extend.contains_one_uni 'condition', UML13::BooleanExpression
UML13::Extend.has_many 'extensionPoint', UML13::ExtensionPoint, :lowerBound => 1
UML13::Extend.has_one 'base', UML13::UseCase, :lowerBound => 1
UML13::Include.has_one 'addition', UML13::UseCase, :lowerBound => 1
UML13::StateMachine.contains_many_uni 'transitions', UML13::Transition
UML13::StateMachine.contains_one_uni 'top', UML13::State, :lowerBound => 1
UML13::Event.contains_many_uni 'parameters', UML13::Parameter
UML13::State.contains_one_uni 'doActivity', UML13::Action
UML13::State.contains_many_uni 'internalTransition', UML13::Transition
UML13::State.has_many 'deferrableEvent', UML13::Event
UML13::State.contains_one_uni 'exit', UML13::Action
UML13::State.contains_one_uni 'entry', UML13::Action
UML13::TimeEvent.contains_one_uni 'when', UML13::TimeExpression
UML13::SignalEvent.many_to_one 'signal', UML13::Signal, 'occurrence', :lowerBound => 1
UML13::Transition.many_to_one 'target', UML13::StateVertex, 'incoming', :lowerBound => 1
UML13::Transition.many_to_one 'source', UML13::StateVertex, 'outgoing', :lowerBound => 1
UML13::Transition.has_one 'trigger', UML13::Event
UML13::Transition.contains_one_uni 'effect', UML13::Action
UML13::Transition.contains_one_uni 'guard', UML13::Guard
UML13::CompositeState.contains_many 'subvertex', UML13::StateVertex, 'container', :lowerBound => 1
UML13::ChangeEvent.contains_one_uni 'changeExpression', UML13::BooleanExpression
UML13::Guard.contains_one_uni 'expression', UML13::BooleanExpression
UML13::SubmachineState.has_one 'submachine', UML13::StateMachine, :lowerBound => 1
UML13::Collaboration.has_one 'representedOperation', UML13::Operation
UML13::Collaboration.has_one 'representedClassifier', UML13::Classifier
UML13::Collaboration.has_many 'constrainingElement', UML13::ModelElement
UML13::Collaboration.contains_many 'interaction', UML13::Interaction, 'context'
UML13::ClassifierRole.contains_one_uni 'multiplicity', UML13::Multiplicity
UML13::ClassifierRole.has_many 'availableContents', UML13::ModelElement
UML13::ClassifierRole.has_many 'availableFeature', UML13::Feature
UML13::ClassifierRole.has_one 'base', UML13::Classifier, :lowerBound => 1
UML13::AssociationRole.contains_one_uni 'multiplicity', UML13::Multiplicity
UML13::AssociationRole.has_one 'base', UML13::Association
UML13::AssociationEndRole.has_many 'availableQualifier', UML13::Attribute
UML13::AssociationEndRole.has_one 'base', UML13::AssociationEnd
UML13::Message.has_one 'action', UML13::Action, :lowerBound => 1
UML13::Message.has_one 'communicationConnection', UML13::AssociationRole
UML13::Message.has_many 'predecessor', UML13::Message
UML13::Message.has_one 'receiver', UML13::ClassifierRole, :lowerBound => 1
UML13::Message.has_one 'sender', UML13::ClassifierRole, :lowerBound => 1
UML13::Message.has_one 'activator', UML13::Message
UML13::Interaction.contains_many 'message', UML13::Message, 'interaction', :lowerBound => 1
UML13::Interaction.contains_many_uni 'link', UML13::Link
UML13::Instance.contains_many_uni 'slot', UML13::AttributeLink
UML13::Instance.one_to_many 'linkEnd', UML13::LinkEnd, 'instance'
UML13::Instance.has_many 'classifier', UML13::Classifier, :lowerBound => 1
UML13::Signal.one_to_many 'reception', UML13::Reception, 'signal'
UML13::CreateAction.has_one 'instantiation', UML13::Classifier, :lowerBound => 1
UML13::Action.contains_one_uni 'recurrence', UML13::IterationExpression
UML13::Action.contains_one_uni 'target', UML13::ObjectSetExpression
UML13::Action.contains_one_uni 'script', UML13::ActionExpression
UML13::Action.contains_many_uni 'actualArgument', UML13::Argument
UML13::AttributeLink.has_one 'value', UML13::Instance, :lowerBound => 1
UML13::AttributeLink.has_one 'attribute', UML13::Attribute, :lowerBound => 1
UML13::CallAction.has_one 'operation', UML13::Operation, :lowerBound => 1
UML13::SendAction.has_one 'signal', UML13::Signal, :lowerBound => 1
UML13::ActionSequence.contains_many_uni 'action', UML13::Action
UML13::Argument.contains_one_uni 'value', UML13::Expression
UML13::Link.contains_many_uni 'connection', UML13::LinkEnd, :lowerBound => 2
UML13::Link.has_one 'association', UML13::Association, :lowerBound => 1
UML13::LinkEnd.has_one 'associationEnd', UML13::AssociationEnd, :lowerBound => 1
UML13::LinkEnd.has_one 'participant', UML13::Instance, :lowerBound => 1
UML13::Stimulus.has_one 'dispatchAction', UML13::Action, :lowerBound => 1
UML13::Stimulus.has_one 'communicationLink', UML13::Link
UML13::Stimulus.has_one 'receiver', UML13::Instance, :lowerBound => 1
UML13::Stimulus.has_one 'sender', UML13::Instance, :lowerBound => 1
UML13::Stimulus.has_many 'argument', UML13::Instance
UML13::ComponentInstance.has_many 'resident', UML13::Instance
UML13::NodeInstance.has_many 'resident', UML13::ComponentInstance
UML13::ActivityGraph.contains_many_uni 'partition', UML13::Partition
UML13::Partition.has_many 'contents', UML13::ModelElement
UML13::SubactivityState.contains_one_uni 'dynamicArguments', UML13::ArgListsExpression
UML13::ObjectFlowState.has_one 'type', UML13::Classifier, :lowerBound => 1
UML13::ObjectFlowState.has_one 'available', UML13::Parameter, :lowerBound => 1
UML13::ClassifierInState.has_one 'type', UML13::Classifier, :lowerBound => 1
UML13::ClassifierInState.has_many 'inState', UML13::State
UML13::ActionState.contains_one_uni 'dynamicArguments', UML13::ArgListsExpression
UML13::Package.contains_many 'importedElement', UML13::ElementImport, 'package'
UML13::Diagram.contains_many 'element', UML13::DiagramElement, 'diagram'
UML13::Diagram.has_one 'owner', UML13::ModelElement, :lowerBound => 1
