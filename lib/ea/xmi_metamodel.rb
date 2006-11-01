module XMIMetaModel

	module UML
	
		include RGen::MetamodelBuilder
		class Classifier_feature < MMBase
			has_many 'operation'
		end
		class ClassifierRole < MMBase
		end
		class Clazz < ClassifierRole
			has_many 'modelElement_stereotype'
		end
		class Operation < MMBase
			has_one 'parent'
		end
		class Generalization < MMBase
		end
		class ModelElement_stereotype < MMBase
			has_one 'parent'
		end
		class AssociationEnd < MMBase
		end
		class AssociationEndRole < MMBase
		end
		ClassifierRole.one_to_many 'associationEnds', AssociationEnd, 'typeClass'
		ClassifierRole.one_to_many 'associationEndRoles', AssociationEndRole, 'typeClass'
		Clazz.one_to_many 'generalizationsAsSubtype', Generalization, 'subtypeClass'
		Clazz.one_to_many 'generalizationsAsSupertype', Generalization, 'supertypeClass'
	
	end

end
	
