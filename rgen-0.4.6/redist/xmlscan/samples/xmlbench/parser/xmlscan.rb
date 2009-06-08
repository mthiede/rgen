#
# samples/xmlbench/parser/xmlscan.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlscan.rb,v 1.2 2003/01/18 07:05:19 katsu Exp $
#

require 'xmlscan/scanner'
require 'xmlscan/parser'
require 'xmlscan/namespace'
require 'xmlscan/xmlchar'


class BenchXMLScan < XMLBench

  class Visitor
    include XMLScan::Visitor
  end

  def name
    'XMLScan::XMLScanner'
  end

  def parse(src)
    XMLScan::XMLScanner.new(Visitor.new).parse src
  end

end



class BenchXMLScanParser < XMLBench

  class Visitor
    include XMLScan::Visitor
    def on_stag(*)            @attrs = {}                end
    def on_attribute(name)    @attrs[name] = @attr = ''  end
    def on_attr_value(str)    @attr << str               end
    def on_attr_charref(str)  @attr << [str].pack('U')   end
  end

  def name
    'XMLScan::XMLParser'
  end

  def parse(src)
    XMLScan::XMLParser.new(Visitor.new).parse src
  end

end



class BenchXMLScanParserNamespace < XMLBench

  class Visitor
    include XMLScan::NSVisitor
    def on_stag_ns(*)              @attrs = {}                end
    def on_attribute_ns(name,p,l)  @attrs[name] = @attr = ''  end
    def on_attr_value(str)         @attr << str               end
    def on_attr_charref(str)       @attr << [str].pack('U')   end
  end

  def name
    'XMLScan::XMLNamespace'
  end

  def parse(src)
    XMLScan::XMLParserNS.new(Visitor.new).parse src
  end

end



class BenchXMLScanParserStrict < XMLBench

  class Visitor
    include XMLScan::Visitor
    def on_stag(*)            @attrs = {}                end
    def on_attribute(name)    @attrs[name] = @attr = ''  end
    def on_attr_value(str)    @attr << str               end
    def on_attr_charref(str)  @attr << [str].pack('U')   end
  end

  def name
    'XMLScan::XMLParser (strict)'
  end

  def weight
    10
  end

  def parse(src)
    XMLScan::XMLParser.new(Visitor.new, :strict_char).parse src
  end

end
