require 'rgen/name_helper'

module UMLClassModel
	class UMLPackage
		include RGen::NameHelper
		
		def moduleName
			firstToUpper(name)
		end
		
		def qualifiedModuleName(rootPackage)
			return moduleName unless superpackage and self != rootPackage
			superpackage.qualifiedModuleName(rootPackage) + "::" + moduleName
		end
		
		def sortedClasses
			sortArray = classes.dup
			i1 = 0
			while i1 < sortArray.size-1
				again = false
				for i2 in i1+1..sortArray.size-1
					e2 = sortArray[i2]
					if sortArray[i1].superclasses.include?(e2)
						sortArray.delete(e2)
						sortArray.insert(i1,e2)
						again = true
						break
					end
				end
				i1 += 1 unless again
			end
			sortArray
		end
	end
	
	class UMLClass
		include RGen::NameHelper
		def className
			firstToUpper(name)			
		end
		def qualifiedName(rootPackage)
			(package ? package.qualifiedModuleName(rootPackage) + "::" : "") + className
		end
		def RubySuperclass(modules)
			superclasses = self.superclasses.reject {|c| modules.include?(c.name)}
			raise StandardError.new("#{self.name}: Duplicate superclasses: #{superclasses}") unless superclasses.size < 2
			superclasses[0]
		end
	end
	
	class UMLAttribute
		def RubyType
			typeMap = {'float' => 'Float', 'int' => 'Integer'}
			typeMap[self.getType.downcase] || 'String'
		end
	end
	
	class UMLAssociationEnd
		def MName
			return self.clazz.name.downcase unless role
			self.role
		end
		def one?
			self.upperMult == 1 or self.upperMult.nil?
		end
		def many?
			self.upperMult == :many
		end
	end
	
end