require 'rgen/metamodel_builder'

module UMLClassModel

include RGen::MetamodelBuilder

class UMLPackage < MMBase
	has_attr 'name', String
	def allClasses
		subpackages.inject(classes) {|r,p| r.concat(p.allClasses) }
	end
end

class UMLClass < MMBase
	has_attr 'name', String
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

class UMLOperation < MMBase
	has_attr 'name', String
end

class UMLAttribute < MMBase
	has_attr 'name', String
	has_attr 'type', String
end

class UMLTaggedValue < MMBase
	has_attr 'tag'
	has_attr 'value'
end

class UMLAssociation < MMBase
end

class UMLAggregation < UMLAssociation
end	

class UMLAssociationEnd < MMBase
	has_attr 'multiplicity', String
	has_attr 'navigable', Boolean
	has_attr 'composite', Boolean
	has_attr 'role', String
	def assoc
		assocA || assocB
	end
	def otherEnd
		return unless assoc
		assoc.endA == self ? assoc.endB : assoc.endA		
	end
	def lowerMult
		return unless multiplicity
		stringToMult(multiplicity.split("..")[0])
	end
	def upperMult
		return unless multiplicity
		ma = multiplicity.split("..")
		stringToMult(ma[1] || ma[0])
	end
	private
	def stringToMult(s)
		return :many if s == "*"
		return s.to_i
	end
end

class UMLStereotype < MMBase
	has_attr 'name'
end


UMLPackage.one_to_many 'subpackages', UMLPackage, 'superpackage'
UMLPackage.one_to_many 'classes', UMLClass, 'package'

UMLClass.many_to_many 'superclasses', UMLClass, 'subclasses'
UMLClass.one_to_many 'assocEnds', UMLAssociationEnd, 'clazz'
UMLClass.one_to_many 'attributes', UMLAttribute, 'clazz'
UMLClass.one_to_many 'operations', UMLOperation, 'clazz'
UMLClass.one_to_many 'taggedvalues', UMLTaggedValue, 'clazz'
UMLClass.has_many 'stereotypes', UMLStereotype

UMLAssociation.one_to_one 'endA', UMLAssociationEnd, 'assocA'
UMLAssociation.one_to_one 'endB', UMLAssociationEnd, 'assocB'

end
