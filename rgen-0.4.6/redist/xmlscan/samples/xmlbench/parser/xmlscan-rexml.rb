#
# samples/xmlbench/parser/xmlscan-rexml.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlscan-rexml.rb,v 1.1 2002/12/26 17:32:46 katsu Exp $
#

require 'samples/rexml'


class BenchXMLScanREXML < XMLBench

  def name
    'XMLScan::REXML'
  end

  def parse(src)
    XMLScan::REXML.parse src
  end

end
