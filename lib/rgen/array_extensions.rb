# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/metamodel_builder'

class Array

	def >>(method)
		compact.inject([]) { |r,e| r | ( (o=e.send(method)).is_a?(Array) ? o : [o] ) }
	end
	
	def method_missing(m, *args)
		super unless size == 0 or compact.any?{|e| e.is_a? RGen::MetamodelBuilder::MMBase}
		compact.inject([]) { |r,e|
			if e.is_a? RGen::MetamodelBuilder::MMBase				
				r | ( (o=e.send(m)).is_a?(Array) ? o : [o] ) 
			else
				raise StandardError.new("Trying to call a method on an array element not a RGen MMBase")
			end
		}.compact
	end

end