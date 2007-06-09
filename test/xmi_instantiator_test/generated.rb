require 'rgen/metamodel_builder'

module EA Model
   extend RGen::ECore::ECoreInstantiator
   include RGen::MetamodelBuilder::DataTypes


   class EARootClass < RGen::MetamodelBuilder::MMBase
   end


   module Buildtime
      extend RGen::ECore::ECoreInstantiator
      include RGen::MetamodelBuilder::DataTypes


      class RunnableEntity < RGen::MetamodelBuilder::MMBase
         has_attr 'category', Integer
         has_attr 'wcet', Integer
      end

      class TimeTriggeredOperation < RunnableEntity
         has_attr 'interval', Integer
         has_attr 'offset', Integer
      end

      class Characteristic < Variable
         has_attr 'longName', String
      end

      class IComposite < RGen::MetamodelBuilder::MMBase
      end

      class SoftwareComponentSpecification < RGen::MetamodelBuilder::MMBase
      end

      class SoftwareComponentType < SoftwareComponentSpecification
      end

      class AtomicSoftwareComponentType < SoftwareComponentType
         has_attr 'languageID', String
         has_attr 'binary', Boolean
         has_attr 'allowMultiplePrototypesPerContainer', Boolean
         has_attr 'shutdownRunnablePresent', Boolean
         has_attr 'startupRunnablePresent', Boolean
         has_attr 'memMapMSN', String
         has_attr 'selectivePortInteraction', Boolean
      end

      class ExclusiveArea < RGen::MetamodelBuilder::MMBase
      end

      class RunnableEntityCanEnterExclusiveArea < RGen::MetamodelBuilder::MMBase
      end

      class Interface < RGen::MetamodelBuilder::MMBase
         has_attr 'serviceInterface', Boolean
      end

      class ClientServerInterface < Interface
      end

      class Argument < Variable
         has_attr 'direction', String
         has_attr 'DIRECTION_IN', String
         has_attr 'DIRECTION_OUT', String
         has_attr 'DIRECTION_INOUT', String
      end

      class Operation < RGen::MetamodelBuilder::MMBase
      end

      class CSResultRunnable < RunnableEntity
      end

      class ServerOperation < RunnableEntity
         has_attr 'calledFromRemote', Boolean, :derived => true
         has_attr 'calledAsynchronously', Boolean, :derived => true
      end

      class SenderReceiverInterface < Interface
      end

      class DataElement < Variable
         has_attr 'informationType', String
         has_attr 'infoTypeData', Boolean, :derived => true
         has_attr 'infoTypeEvent', Boolean, :derived => true
      end

      class ReceptionRunnable < RunnableEntity
      end

      class ErrorHandler < RGen::MetamodelBuilder::MMBase
         has_attr 'type', String
      end

      class ErrorRunnable < RunnableEntity
      end

      class Port < RGen::MetamodelBuilder::MMBase
         has_attr 'receiveMode', String
         has_attr 'receiveModeDRA', Boolean, :derived => true
         has_attr 'sRPort', Boolean, :derived => true
         has_attr 'cSPort', Boolean, :derived => true
         has_attr 'receiveModeARE', Boolean, :derived => true
         has_attr 'senderPort', Boolean, :derived => true
         has_attr 'receiverPort', Boolean, :derived => true
         has_attr 'clientPort', Boolean, :derived => true
         has_attr 'serverPort', Boolean, :derived => true
         has_attr 'clientMode', String
         has_attr 'clientModeSync', Boolean, :derived => true
         has_attr 'clientModeAsync', Boolean, :derived => true
      end

      class RequiredPort < Port
      end

      class ProvidedPort < Port
      end

      class TerminatorSoftwareComponentType < AtomicSoftwareComponentType
      end

      class ActuatorSoftwareComponentType < TerminatorSoftwareComponentType
      end

      class ConfigurationProperty < Variable
      end

      class PrototypeProperty < ConfigurationProperty
      end

      class LegacyComponentType < SoftwareComponentType
      end

      class DeployedPrototypeProperty < ConfigurationProperty
      end

      class ConfigurationParameterSetting < RGen::MetamodelBuilder::MMBase
         has_attr 'value', String
      end

      class CompositionType < SoftwareComponentType
      end

      class SensorSoftwareComponentType < TerminatorSoftwareComponentType
      end

   end
end

EA Model::Buildtime::AtomicSoftwareComponentType.contains_many 'timeTriggeredOperation', EA Model::Buildtime::TimeTriggeredOperation, 'component'
EA Model::Buildtime::AtomicSoftwareComponentType.contains_many 'characteristic', EA Model::Buildtime::Characteristic, 'componentType'
EA Model::Buildtime::Characteristic.one_to_many 'configDataBuffer', ConfigDataBuffer, 'characteristic'
EA Model::Buildtime::IComposite.contains_many 'componentPrototype', AbstractComponentPrototype, 'composition'
EA Model::Buildtime::IComposite.contains_many 'connector', Connector, 'composition'
EA Model::Buildtime::SoftwareComponentType.has_one 'specification', EA Model::Buildtime::SoftwareComponentSpecification
EA Model::Buildtime::SoftwareComponentType.one_to_many 'componentPrototype', AbstractComponentPrototype, 'type'
EA Model::Buildtime::AtomicSoftwareComponentType.contains_many 'exclusiveArea', EA Model::Buildtime::ExclusiveArea, 'component'
EA Model::Buildtime::AtomicSoftwareComponentType.has_many 'runnableEntity', EA Model::Buildtime::RunnableEntity
EA Model::Buildtime::ExclusiveArea.has_many 'resource', Resource
EA Model::Buildtime::ExclusiveArea.one_to_many 'runnableEntityCanEnterExclusiveArea', EA Model::Buildtime::RunnableEntityCanEnterExclusiveArea, 'exclusiveArea'
EA Model::Buildtime::RunnableEntityCanEnterExclusiveArea.many_to_one 'runnableEntity', EA Model::Buildtime::RunnableEntity, 'runnableEntityCanEnterExclusiveArea', :lowerBound => 1
EA Model::Buildtime::RunnableEntity.contains_many 'portInteraction', PortInteraction, 'runnableEntity'
EA Model::Buildtime::RunnableEntity.has_many 'dataWriteAccess', DataWriteAccess
EA Model::Buildtime::RunnableEntity.has_many 'synchronousServerCallPoint', SynchronousServerCallPoint
EA Model::Buildtime::RunnableEntity.has_many 'dataSendPoint', DataSendPoint
EA Model::Buildtime::RunnableEntity.has_many 'dataReadAccess', DataReadAccess
EA Model::Buildtime::RunnableEntity.has_many 'dataReceivePoint', DataReceivePoint
EA Model::Buildtime::RunnableEntity.one_to_many 'runnableStartEvent', RunnableStartEvent, 'runnableEntity'
EA Model::Buildtime::RunnableEntity.one_to_many 'runnableEndEvent', RunnableEndEvent, 'runnableEntity'
EA Model::Buildtime::RunnableEntity.has_many 'runnableEvent', RunnableEvent
EA Model::Buildtime::RunnableEntity.one_to_many 'runnableEntitySchedule', RunnableEntitySchedule, 'runnableEntity'
EA Model::Buildtime::Interface.one_to_many 'port', EA Model::Buildtime::Port, 'interface'
EA Model::Buildtime::Interface.has_many 'associatedElement', Variable
EA Model::Buildtime::Interface.one_to_one 'stateMachine', InterfaceState, 'interface'
EA Model::Buildtime::ClientServerInterface.contains_many 'operation', EA Model::Buildtime::Operation, 'interface'
EA Model::Buildtime::Operation.contains_many 'argument', EA Model::Buildtime::Argument, 'operation'
EA Model::Buildtime::Operation.one_to_many 'serverCallPoint', ServerCallPoint, 'operation'
EA Model::Buildtime::Operation.one_to_one 'CSResultRunnable', EA Model::Buildtime::CSResultRunnable, 'operation'
EA Model::Buildtime::Port.contains_many 'CSResultRunnable', EA Model::Buildtime::CSResultRunnable, 'port'
EA Model::Buildtime::Port.contains_many 'serverOperation', EA Model::Buildtime::ServerOperation, 'port'
EA Model::Buildtime::ServerOperation.has_one 'operation', EA Model::Buildtime::Operation, :lowerBound => 1
EA Model::Buildtime::SenderReceiverInterface.has_many 'infoTypeDataDataElement', EA Model::Buildtime::DataElement
EA Model::Buildtime::SenderReceiverInterface.has_many 'infoTypeEventDataElement', EA Model::Buildtime::DataElement
EA Model::Buildtime::SenderReceiverInterface.contains_many 'dataElement', EA Model::Buildtime::DataElement, 'interface'
EA Model::Buildtime::DataElement.has_many 'adu', ADU
EA Model::Buildtime::DataElement.one_to_many 'sRBuffer', SRBuffer, 'dataElement'
EA Model::Buildtime::DataElement.one_to_many 'portTimingEventPrototype', PortTimingEventPrototype, 'dataElement'
EA Model::Buildtime::DataElement.one_to_many 'senderComSpec', SenderComSpec, 'dataElement'
EA Model::Buildtime::DataElement.one_to_many 'sRPortInteraction', SRPortInteraction, 'dataElement'
EA Model::Buildtime::DataElement.one_to_many 'receiverComSpec', ReceiverComSpec, 'dataElement'
EA Model::Buildtime::Port.contains_many 'receptionRunnable', EA Model::Buildtime::ReceptionRunnable, 'port'
EA Model::Buildtime::ReceptionRunnable.has_one 'dataElement', EA Model::Buildtime::DataElement, :lowerBound => 1
EA Model::Buildtime::Port.contains_many 'errorRunnable', EA Model::Buildtime::ErrorRunnable, 'port'
EA Model::Buildtime::ErrorRunnable.has_one 'dataElement', EA Model::Buildtime::DataElement, :lowerBound => 1
EA Model::Buildtime::SoftwareComponentSpecification.contains_many 'port', EA Model::Buildtime::Port, 'component'
EA Model::Buildtime::Port.has_one 'runnableEntity', EA Model::Buildtime::RunnableEntity
EA Model::Buildtime::Port.one_to_many 'targetPortRef', TargetPortRef, 'port'
EA Model::Buildtime::Port.has_one 'errorHandler', EA Model::Buildtime::ErrorHandler
EA Model::Buildtime::Port.one_to_many 'portPrototype', PortPrototype, 'port'
EA Model::Buildtime::Port.one_to_many 'portInteraction', PortInteraction, 'port'
EA Model::Buildtime::SoftwareComponentSpecification.has_many 'requiredPort', EA Model::Buildtime::RequiredPort
EA Model::Buildtime::SoftwareComponentSpecification.has_many 'providedPort', EA Model::Buildtime::ProvidedPort
EA Model::Buildtime::ActuatorSoftwareComponentType.has_one 'actuatorHardware', ActuatorHardware
EA Model::Buildtime::ConfigurationParameterSetting.has_one 'property', EA Model::Buildtime::ConfigurationProperty, :lowerBound => 1
EA Model::Buildtime::SensorSoftwareComponentType.has_one 'sensorHardware', SensorHardware
