require 'rgen/metamodel_builder'
require 'rgen/instantiator'
require 'rgen/name_helper'
require 'rexml/parsers/sax2parser'
require 'rexml/sax2listener'

module RGen

class XMLInstantiator < Instantiator
	include REXML::SAX2Listener
	include NameHelper
	
	class << self
		def tag_ns_map
			@tag_ns_map ||={}
			@tag_ns_map
		end
	end

	class XMLElementDescriptor
		attr_reader :tag, :mod, :parent, :attributes
		attr_accessor :object, :children
		def initialize(tag, mod, parent, children, attributes)
			@tag, @mod, @parent, @children, @attributes = tag, mod, parent, children, attributes
			@parent.children << self if @parent
		end
	end
	
	NamespaceDescriptor = Struct.new(:prefix, :target)
	
	def self.map_tag_ns(from, to, prefix="")
		tag_ns_map[from] = NamespaceDescriptor.new(prefix, to)
	end
	
	def initialize(env, mod, createMM=false)
		super(env,mod)
		@env = env
		@default_module = mod
		@createMM = createMM
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
		parser = REXML::Parsers::SAX2Parser.new(src)
		parser.listen(self)
		parser.parse
	end	
	
	def start_element(ns, tag, qtag, attributes)
		ns_desc = self.class.tag_ns_map[ns]
		tag = ns_desc.nil? ? qtag : ns_desc.prefix+tag
		mod = (ns_desc && ns_desc.target) || @default_module		
		@stack.push XMLElementDescriptor.new(tag, mod, @stack[-1], [], attributes)
	end

	def end_element(uri, localname, qname)	
		elementDesc = @stack.pop
		obj = callBuildMethod(:new_object, NameError, :create_class, elementDesc.mod, elementDesc)
		@env << obj
		elementDesc.object = obj
		elementDesc.children.each { |c|
			callBuildMethod(:assoc_p2c, NoMethodError, :create_p2c_assoc, elementDesc, c)
		}
		elementDesc.attributes.each_pair {|k,v|
			callBuildMethod(:set_attribute, NoMethodError, :create_attribute, elementDesc, k, v)
		}
		# optionally prune children to save memory
		#elementDesc.children = nil
	end
	
	def callBuildMethod(method, exception, mmMethod, *args)
		begin
			send(method, *args)
		rescue exception
			if @createMM
				send(mmMethod, *args)
				send(method, *args)
			else
				raise
			end
		end
	end

	# Model and Metamodel builder methods
	# These methods are to be overwritten by specific instantiators
	def new_object(mod, node)
		mod.const_get(saneClassName(node)).new
	end
	
	def create_class(mod, node)
		mod.const_set(saneClassName(node), Class.new(RGen::MetamodelBuilder::MMBase))
	end

	def assoc_p2c(parent, child)
		parent.object.addGeneric(saneMethodName(child), child.object)
		child.object.setGeneric("parent", parent.object)
	end
	
	def create_p2c_assoc(parent, child)
		parent.object.class.has_many(saneMethodName(child), child.object.class)
		child.object.class.has_one("parent", RGen::MetamodelBuilder::MMBase)
	end
	
	def set_attribute(node, attr, value)
		node.object.setGeneric(normalize(attr), value)
	end
	
	def create_attribute(node, attr, value)
		node.object.class.has_one(normalize(attr))
	end
					
	def saneClassName(node)
		firstToUpper(normalize(node.tag)).sub(/^Class$/, 'Clazz')
	end
	
	def saneMethodName(node)
		firstToLower(normalize(node.tag)).sub(/^class$/, 'clazz')
	end	
					
end

end