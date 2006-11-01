# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/template_language/template_container'
require 'rgen/template_language/template_helper'

module RGen

module TemplateLanguage

class DirectoryTemplateContainer
	include TemplateHelper
	
	def initialize(metamodel=nil, output_path=nil, parent=nil)
		@containers = {}
		@parent = parent
		@metamodel = metamodel
		@output_path = output_path
	end
	
	def load(dir)
		#print "Loading templates in #{dir} ...\n"
		Dir.foreach(dir) { |f|
			qf = dir+"/"+f
			if !File.directory?(qf) && f =~ /^(.*)\.tpl$/
				(@containers[$1] = TemplateContainer.dup.new(@metamodel, @output_path, self)).load(qf)
			elsif File.directory?(qf) && f != "." && f != ".."
				(@containers[f] = DirectoryTemplateContainer.new(@metamodel, @output_path, self)).load(qf)
			end
		}
	end
	
	def expand(template, *all_args)
		args, params = _splitArgsAndOptions(all_args)
		element = params[:for]
		if template =~ /^\// && @parent
			@parent.expand(template, *all_args)
		elsif template =~ /^[\/]*(\w+)[:\/]+(.*)/ 
			throw "Template not found: #{$1}" unless @containers[$1]
			@containers[$1].expand($2, *all_args)
		elsif @parent
			@parent.expand(template, *all_args)
		else
			throw "Template not found: #{template}"
		end
	end
end

end

end