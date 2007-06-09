# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/name_helper'

module RGen

module MetamodelBuilder

class BuildHelper
	include NameHelper
	
	def self.build(mod,bnd,tpl)
		mod.module_eval ERB.new(tpl).result(BuildHelper.new(mod, bnd).bnd)
	end
	def initialize(mod, bnd)
		@outer_binding = bnd
		@mod = mod
	end
	def bnd
		binding
	end
	def method_missing(m, *args)
		if args.empty?
			eval("#{m}",@outer_binding)
		else
			@mod.instance_eval do
				send(m,*args)
			end
		end
	end
	def type_check_code(varname, props)
		code = ""
		if props.impl_type.is_a?(Class)
			code << "unless #{varname}.nil? or #{varname}.is_a? #{props.impl_type}\n"
			expected = props.impl_type.to_s
		elsif props.impl_type.is_a?(RGen::MetamodelBuilder::DataTypes::Enum)
			code << "unless #{varname}.nil? or [#{props.impl_type.literals_as_strings.join(',')}].include?(#{varname})\n"
		    expected = "["+props.impl_type.literals_as_strings.join(',')+"]"
		else
			raise StandardError.new("Unkown type "+props.impl_type.to_s)
		end
		code << "raise _assignmentTypeError(self,#{varname},\"#{expected}\")\n"
		code << "end"
		code		
	end
end

end

end