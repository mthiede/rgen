# RGen Framework

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

  def build_from_value(value)
    instance = self.new

    raise SingleAttributeRequired.new(self.ecore.name,self.ecore.eAllAttributes) if self.ecore.eAllAttributes.count!=1
    attribute = self.ecore.eAllAttributes[0]
    instance.send(:"#{attribute.name}=",value)
    instance
  end

end

end

end
