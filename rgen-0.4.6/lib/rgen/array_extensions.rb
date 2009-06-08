# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/metamodel_builder'

class Array

	def >>(method)
		compact.inject([]) { |r,e| r | ( (o=e.send(method)).is_a?(Array) ? o : [o] ) }
	end
	
	def method_missing(m, *args)
		super unless size == 0 or compact.any?{|e| e.is_a? RGen::MetamodelBuilder::MMBase}
		# use an array to build the result to achiev similar ordering
		result = []
		inResult = {}
		compact.each do |e|
			if e.is_a? RGen::MetamodelBuilder::MMBase				
				((o=e.send(m)).is_a?(Array) ? o : [o] ).each do |v|
					next if inResult[v.object_id]
					inResult[v.object_id] = true
					result << v
				end
			else
				raise StandardError.new("Trying to call a method on an array element not a RGen MMBase")
			end
		end
		result.compact
	end

end