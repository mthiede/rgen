# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/name_helper'

module RGen

module MetamodelBuilder

class BuildHelper
	include NameHelper
	
	def self.build(mod,bnd,tpl)
		mod.module_eval ERB.new(tpl).result(BuildHelper.new(bnd).bnd)
	end
	def initialize(bnd)
		@outer_binding = bnd
	end
	def bnd
		binding
	end
	def method_missing(m)
		eval("#{m}",@outer_binding)
	end
end

end

end