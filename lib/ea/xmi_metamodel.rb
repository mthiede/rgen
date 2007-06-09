module XMIMetaModel

	module UML
	
		include RGen::MetamodelBuilder
		class Classifier_feature < MMBase
		end
		class ClassifierRole < MMBase
		end
		class Clazz < ClassifierRole
		end
		class Interface < ClassifierRole
		end
		class Operation < MMBase
		end
		class Generalization < MMBase
		end
		class ModelElement_stereotype < MMBase
		end
		class AssociationEnd < MMBase
			def otherEnd
				parent.associationEnd.find{|ae| ae != self}
			end
		end
		class AssociationEndRole < MMBase
		end
		ClassifierRole.one_to_many 'associationEnds', AssociationEnd, 'typeClass'
		ClassifierRole.one_to_many 'associationEndRoles', AssociationEndRole, 'typeClass'
		Clazz.one_to_many 'generalizationsAsSubtype', Generalization, 'subtypeClass'
		Clazz.one_to_many 'generalizationsAsSupertype', Generalization, 'supertypeClass'
	
	end

end
	
