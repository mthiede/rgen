require 'rgen/ecore/ecore'

module RGen

module ModelComparator

def modelEqual?(a, b, featureIgnoreList=[])
  @modelEqual_visited = {}
  _modelEqual_internal(a, b, featureIgnoreList)
end
  
def _modelEqual_internal(a, b, featureIgnoreList)
  return true if @modelEqual_visited[[a,b]]
  @modelEqual_visited[[a,b]] = true
  return true if a.nil? && b.nil?
  return false unless a.class == b.class
  if a.is_a?(Array)
    return false unless a.size == b.size
    a.each_index do |i|
      return false unless _modelEqual_internal(a[i], b[i], featureIgnoreList)
    end
  else
    a.class.ecore.eAllStructuralFeatures.reject{|f| f.derived}.each do |feat|
      next if featureIgnoreList.include?(feat.name)
      if feat.eType.is_a?(RGen::ECore::EDataType)
        unless a.getGeneric(feat.name) == b.getGeneric(feat.name)
          return false
        end
      else
        return false unless _modelEqual_internal(a.getGeneric(feat.name), b.getGeneric(feat.name), featureIgnoreList)
      end
    end
  end
  return true
end

end

end
    