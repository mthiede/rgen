#
# samples/xmlbench/parser/xmlparser.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlparser.rb,v 1.1 2002/12/26 17:32:46 katsu Exp $
#

require 'xmlparser'


class BenchXMLParser < XMLBench

  def name
    'XMLParser'
  end

  def parse(src)
    XMLParser.new.parse src
  end

end
