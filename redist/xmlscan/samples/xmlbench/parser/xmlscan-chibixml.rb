#
# samples/xmlbench/parser/xmlscan-chibixml.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlscan-chibixml.rb,v 1.1 2002/12/26 17:32:46 katsu Exp $
#

require 'samples/chibixml'


class BenchXMLScanChibiXML < XMLBench

  def name
    'XMLScan::ChibiXML'
  end

  def parse(src)
    XMLScan::ChibiXML.parse src
  end

end
