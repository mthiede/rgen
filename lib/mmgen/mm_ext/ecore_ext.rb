require 'rgen/name_helper'

module RGen

module ECore

class EPackage
	include RGen::NameHelper
	
	def moduleName
		firstToUpper(name)
	end
	
	def qualifiedModuleName(rootPackage)
		return moduleName unless eSuperPackage and self != rootPackage
		eSuperPackage.qualifiedModuleName(rootPackage) + "::" + moduleName
	end
		
	def allClassifiers
		eSubpackages.inject(eClassifiers) {|r,p| r.concat(p.allClassifiers) }	 
	end

	def ancestorPackages
	 return [] unless eSuperPackage
	 [eSuperPackage] + eSuperPackage.ancestorPackages
	end
	
	def sortedClasses
		sortArray = eClassifiers.select{|c| c.is_a?(EClass)}
		i1 = 0
		while i1 < sortArray.size-1
			again = false
			for i2 in i1+1..sortArray.size-1
				e2 = sortArray[i2]
				if sortArray[i1].eSuperTypes.include?(e2)
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

class EClassifier
	include RGen::NameHelper
	def classifierName
		firstToUpper(name)			
	end
	def qualifiedName(rootPackage)
		(ePackage ? ePackage.qualifiedModuleName(rootPackage) + "::" : "") + classifierName
	end
	def ancestorPackages
	 return [] unless ePackage
	 [ePackage] + ePackage.ancestorPackages
	end
    def qualifiedNameIfRequired(package)
      if ePackage != package
        commonSuper = (package.ancestorPackages & ancestorPackages).first
        qualifiedName(commonSuper)
      else
        classifierName
      end
    end
end
  
class EAttribute
	def RubyType
		typeMap = {'float' => 'Float', 'int' => 'Integer'}
		(self.getType && typeMap[self.getType.downcase]) || 'String'
	end
end
	
end

end