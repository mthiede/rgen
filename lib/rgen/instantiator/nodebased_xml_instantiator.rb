$:.unshift File.join(File.dirname(__FILE__),"..","..","..","redist","xmlscan","lib")

require 'rgen/metamodel_builder'
require 'rgen/instantiator/abstract_instantiator'
require 'xmlscan/namespace'

module RGen

module Instantiator

class NodebasedXMLInstantiator < AbstractInstantiator
	
	class << self

		# The prune level is the number of parent/children associations which
		# is kept when the instantiator ascents the XML tree.
		# If the level is 2, information for the node's children and the childrens'
		# children will be available as an XMLNodeDescriptor object.
		# If the level is 0 no pruning will take place, i.e. the whole information
		# is kept until the end of the instantiation process. 0 is default.
		def set_prune_level(level)
			@prune_level = level
		end

		def prune_level # :nodoc:
			@prune_level ||= 0
		end

	end

	class XMLNodeDescriptor
		attr_reader :namespace, :qtag, :prefix, :tag, :parent, :attributes, :chardata
		attr_accessor :object, :children
		
		def initialize(ns, qtag, prefix, tag, parent, children, attributes)
			@namespace, @qtag, @prefix, @tag, @parent, @children, @attributes = 
				ns, qtag, prefix, tag, parent, children, attributes
			@parent.children << self if @parent
			@chardata = []
		end
	end
	
	class XMLScanVisitor
	    attr_reader :namespaces
	    
		include XMLScan::NSVisitor
	
		def initialize(inst)
			@current_attributes = {}
			@instantiator = inst
		end
		
		def on_attribute_ns(qname, prefix, localpart)
			@current_attr_name = qname
		end
	
		def on_attr_value(str)
			@current_attributes[@current_attr_name] = str
		end
		
		def on_stag_end_ns(qname, namespaces)
		    @namespaces = namespaces
			if qname =~ /^([^:]+):([^:]+)$/
				prefix, tag = $1, $2
			else
				prefix, tag = nil, qname
			end
			@instantiator.start_element(namespaces[prefix], qname, prefix, tag, @current_attributes)
			@current_attributes = {}
		end
		
		def on_stag_end_empty_ns(qname, namespaces)
			on_stag_end_ns(qname, namespaces)
			@instantiator.end_element
		end
		
		def on_etag(name)
			@instantiator.end_element
		end
		
		def on_chardata(str)
			@instantiator.on_chardata(str)
		end
	end
	
	def initialize(env)
		super
		@env = env
		@stack = []
	end
	
	def instantiate_file(file)
		File.open(file) { |f| parse(f.read)}
		resolve
	end
	
	def instantiate(text)
		parse(text)
		resolve
	end
		
	def parse(src)
	    @visitor = XMLScanVisitor.new(self)
		parser = XMLScan::XMLParserNS.new(@visitor)
	    parser.parse(src)
		@visitor = nil
	end	
		
	def start_element(ns, qtag, prefix, tag, attributes)
		node = XMLNodeDescriptor.new(ns, qtag, prefix, tag, @stack[-1], [], attributes)
		@stack.push node
		on_descent(node)
	end
	
	def end_element
		node = @stack.pop
		on_ascent(node)
		prune_children(node, self.class.prune_level - 1) if self.class.prune_level > 0
	end
	
	def on_chardata(str)
		node = @stack.last
		node.chardata << str
	end

	# This method is called when the XML parser goes down the tree.
	# An XMLNodeDescriptor +node+ describes the current node.
	# Implementing classes must overwrite this method.
	def on_descent(node)
		raise "Overwrite this method !"
	end
	
	# This method is called when the XML parser goes up the tree.
	# An XMLNodeDescriptor +node+ describes the current node.
	# Implementing classes must overwrite this method.
	def on_ascent(node)
		raise "Overwrite this method !"
	end

    def namespaces
      @visitor.namespaces if @visitor
    end
    
	private
	
	def prune_children(node, level)
		if level == 0
			node.children = nil
		else
			node.children.each { |c| prune_children(c, level-1) }
		end
	end					
end

end

end