require 'rgen/metamodel_builder'

module UMLObjectModel

include RGen::MetamodelBuilder

class UMLPackage < MMBase
	has_one 'name', String
	def allObjects
		subpackages.inject(objects) {|r,p| r.concat(p.allObjects) }
	end
end

class UMLObject < MMBase
	has_one 'name', String
	has_one 'classname', String
	def remoteNavigableEnds
		assocEnds.otherEnd.select{|e| e.navigable}
	end
	def localNavigableEnds
		assocEnds.select{|e| e.navigable}
	end
	def localCompositeEnds
		assocEnds.select{|e| e.composite}
	end
	def remoteCompositeEnds
		assocEnds.otherEnd.select{|e| e.composite}
		# put constraint check here and return the container directly ?
	end
end

class UMLAttributeSetting < MMBase
	has_one 'name', String
	has_one 'value', String
end

class UMLAssociation < MMBase
end

class UMLAggregation < UMLAssociation
end	

class UMLAssociationEnd < MMBase
	has_one 'navigable' # boolean
	has_one 'composite' # boolean
	has_one 'role', String
	def assoc
		assocA || assocB
	end
	def otherEnd
		return unless assoc
		assoc.endA == self ? assoc.endB : assoc.endA		
	end
end

UMLPackage.one_to_many 'subpackages', UMLPackage, 'superpackage'
UMLPackage.one_to_many 'objects', UMLObject, 'package'

UMLObject.one_to_many 'assocEnds', UMLAssociationEnd, 'object'
UMLObject.one_to_many 'attributeSettings', UMLAttributeSetting, 'object'

UMLAssociation.one_to_one 'endA', UMLAssociationEnd, 'assocA'
UMLAssociation.one_to_one 'endB', UMLAssociationEnd, 'assocB'

end
