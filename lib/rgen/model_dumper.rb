module RGen

module ModelDumper

	def dump(obj=nil)
		obj ||= self
		if obj.is_a?(Array)
			obj.collect {|o| dump(o)}.join("\n\n")
		elsif obj.class.respond_to?(:one_attributes) && obj.class.respond_to?(:many_attributes)
			([obj.to_s] +
			obj.class.one_attributes.collect { |a| 
				"   #{a} => #{obj.getGeneric(a)}"
			} +
			obj.class.many_attributes.collect { |a|
				"   #{a} => [ #{obj.getGeneric(a).join(', ')} ]"
			}).join("\n")
		else
			obj.to_s
		end
	end

end

end