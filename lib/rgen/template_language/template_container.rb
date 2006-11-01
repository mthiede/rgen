# RGen Framework
# (c) Martin Thiede, 2006

require 'erb'
require 'rgen/template_language/output_handler'
require 'rgen/template_language/template_helper'

module RGen

module TemplateLanguage

class TemplateContainer
	include TemplateHelper
	
	def initialize(metamodel, output_path, parent)
		@templates = {}
		@parent = parent
		@indent = 0
		@output_path = output_path
		raise StandardError.new("Can not set metamodel, dup class first") if self.class == TemplateContainer
		@@metamodel = metamodel
	end

	def load(filename)
		#print "Loading templates in #{filename} ...\n"
		File.open(filename) { |f|
			ERB.new(f.read,nil,nil,'@output').result(binding)
		}
	end
	
	# if this container can handle the call, the expansion result is returned
	# otherwise expand is called on the appropriate container and the result is added to @output
	def expand(template, *all_args)
		args, params = _splitArgsAndOptions(all_args)
		if params[:foreach].is_a? Enumerable
			_expand_foreach(template, args, params)
		else
			_expand(template, args, params)
		end
	end
	
	def this
		@context
	end
	
	def method_missing(name, *args)
		@context.send(name, *args)
	end
	
	def self.const_missing(name)
		super unless @@metamodel
		@@metamodel.const_get(name) 
	end
	
	private

	def nonl
		@output.ignoreNextNL
	end

	def nows
		@output.ignoreNextWS
	end
	
	def nl
		_direct_concat("\n")
	end
	
	def iinc
		@indent += 1
		@output.indent = @indent
	end
	
	def idec
		@indent -= 1 if @indent > 0
		@output.indent = @indent
	end
	
	def define(template, params={}, &block)
		@templates[template] ||= {}
		cls = params[:for] || Object
		@templates[template][cls] = block
	end
	
	def file(name)
		old_output, @output = @output, OutputHandler.new(@indent)
		yield
		path = ""
		path += @output_path+"/" if @output_path
		File.open(path+name,"w") { |f| f.write(@output) }
		@output = old_output
	end

	# private private
	
	def _expand_foreach(template, args, params)
		params[:foreach].each {|e|
			single_params = params.dup
			single_params[:for] = e
			_expand(template, args, single_params)
		}
	end

	LOCAL_TEMPLATE_REGEX = /^:*(\w+)$/

	def _expand(template, args, params)
		context = params[:for]
		@indent = params[:indent] || @indent
		old_context, @context = @context, context if context
		local_output = nil
		if template =~ LOCAL_TEMPLATE_REGEX
			throw "Template not found: #{$1}" unless @templates[$1]
			old_output, @output = @output, OutputHandler.new(@indent)
			_call_template($1, @context, args)
			local_output, @output = @output, old_output
		else
			local_output = @parent.expand(template, *(args.dup << {:for => @context, :indent => @indent}))
		end
		_direct_concat(local_output)
		@context = old_context if old_context
		local_output
	end
	
	def _call_template(tpl, context, args)
		found = false
		@templates[tpl].each_pair { |key, value| 
			if context.is_a?(key)
				proc = @templates[tpl][key]
				arity = proc.arity
				arity = 0 if arity == -1	# if no args are given
				raise StandardError.new("Wrong number of arguments calling template #{tpl}: #{args.size} for #{arity} "+
					"(Beware: Hashes as last arguments are taken as options and are ignored)") \
					if arity != args.size
				proc.call(*args) 
				found = true
			end
		}
		raise StandardError.new("Template class not matching: #{tpl} for #{context.class.name}") unless found
	end
	
	def _direct_concat(s)
		if @output.is_a? OutputHandler
			@output.direct_concat(s)
		else
			@output << s
		end
	end
	
end

end

end