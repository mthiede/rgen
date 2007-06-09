$:.unshift File.join(File.dirname(__FILE__),"..","..","..","redist","xmlscan","lib")

require 'xmlscan/namespace'

class AbstractXMLInstantiator
    
  class XMLScanVisitor
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
    
    def split_qname(qname)
      if qname =~ /^([^:]+):([^:]+)$/
        prefix, tag = $1, $2
      else
        prefix, tag = nil, qname
      end
      return prefix, tag
    end
    
    def on_stag_end_ns(qname, namespaces)
      prefix, tag = split_qname(qname)
      @instantiator.start_tag(prefix, tag, namespaces, @current_attributes)
      @current_attributes.each_pair { |k,v| @instantiator.set_attribute(k, v) }
      @current_attributes = {}
    end
    
    def on_stag_end_empty_ns(qname, namespaces)
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
  end

  def instantiate(str)
    visitor = XMLScanVisitor.new(self)
	parser = XMLScan::XMLParserNS.new(visitor)
    parser.parse(str)
  end
  
end