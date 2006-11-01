require 'rgen/metamodel_builder'

module RGen

module XMIHelper

class MapHelper
	def initialize(keyMethod,valueMethod,elements)
		@keyMethod, @valueMethod, @elements = keyMethod, valueMethod, elements
	end
	def [](key)
		return @elements.select{|e| e.send(@keyMethod) == key}.first.send(@valueMethod) rescue NoMethodError
		nil
	end
end

class TaggedValueHelper < MapHelper
	def initialize(element)	
		super('tag','value',element.modelElement_taggedValue.taggedValue)
	end
end


end

end