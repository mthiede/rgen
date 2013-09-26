# RGen Framework
# (c) Martin Thiede, 2006

module RGen

module MetamodelBuilder

module InstantiationExtensions

  class SingleAttributeRequired < Exception
    def initialize(class_name,attributes)
      @class_name = class_name
      @attributes = attributes
    end
    def to_s
      names = []
      @attributes.each {|a| names << a.name}
      "SingleAttributeRequired: '#{@class_name}', attributes: #{names.join(', ')}"
    end
  end

  def self.build_from_value(value)
    has_dynamic = false
    self.ecore.eAllAttributes.each {|a| has_dynamic|=a.name=='dynamic'}
    d = 0
    d = 1 if has_dynamic

    raise SingleAttributeRequired.new(self.ecore.name,self.ecore.eAllAttributes) if self.ecore.eAllAttributes.count!=1+d
    attribute = self.ecore.eAllAttributes[0]
    instance.send(:"#{attribute}=",value)
  end

end

end

end
