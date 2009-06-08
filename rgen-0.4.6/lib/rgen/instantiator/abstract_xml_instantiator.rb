$:.unshift File.join(File.dirname(__FILE__),"..","..","..","redist","xmlscan","lib")

require 'xmlscan/namespace'

class AbstractXMLInstantiator
    
  class XMLScanVisitor
    include XMLScan::NSVisitor
    
    def initialize(inst, gcSuspendCount)
      @current_attributes = {}
      @instantiator = inst
      @gcSuspendCount = gcSuspendCount
    end
    
    def on_attribute_ns(qname, prefix, localpart)
      @current_attr_name = qname
    end
    
    def on_attr_value(str)
      @current_attributes[@current_attr_name] = str
    end
    
    def split_qname(qname)
      if qname =~ /^([^:]+):([^:]+)$/
        prefix, tag = $1, $2
      else
        prefix, tag = nil, qname
      end
      return prefix, tag
    end
    
    def on_stag_end_ns(qname, namespaces)
			controlGC
      prefix, tag = split_qname(qname)
      @instantiator.start_tag(prefix, tag, namespaces, @current_attributes)
      @current_attributes.each_pair { |k,v| @instantiator.set_attribute(k, v) }
      @current_attributes = {}
    end
    
    def on_stag_end_empty_ns(qname, namespaces)
			controlGC
      prefix, tag = split_qname(qname)
      @instantiator.start_tag(prefix, tag, namespaces, @current_attributes)
      @current_attributes.each_pair { |k,v| @instantiator.set_attribute(k, v) }
      @current_attributes = {}
      @instantiator.end_tag(prefix, tag)
    end
    
    def on_etag(qname)
      prefix, tag = split_qname(qname)
      @instantiator.end_tag(prefix, tag)
    end
		
		def on_chardata(str)
			@instantiator.text(str)
		end
		
		def controlGC
			return unless @gcSuspendCount > 0
			@gcCounter ||= 0
			@gcCounter += 1
			if @gcCounter == @gcSuspendCount
				@gcCounter = 0
				GC.enable
				ObjectSpace.garbage_collect
				GC.disable 
			end    	
		end
  end

	# Parses str and calls start_tag, end_tag, set_attribute and text methods of a subclass.
	# 
	# If gcSuspendCount is specified, the garbage collector will be disabled for that
	# number of start or end tags. After that period it will clean up and then be disabled again.
	# A value of about 1000 can significantly improve overall performance.
	# The memory usage normally does not increase.
	# Depending on the work done for every xml tag the value might have to be adjusted.
	# 
  def instantiate(str, gcSuspendCount=0)
  	gcDisabledBefore = GC.disable
  	gcSuspendCount = 0 if gcDisabledBefore
  	begin
	    visitor = XMLScanVisitor.new(self, gcSuspendCount)
			parser = XMLScan::XMLParserNS.new(visitor)
			parser.parse(str)
   	ensure 	
    	GC.enable unless gcDisabledBefore
    end
  end
  
	def text(str)
	end
end