#
# samples/xmlbench/parser/chibixml.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: chibixml.rb,v 1.1 2002/12/26 17:32:46 katsu Exp $
#

require 'chibiparse'


class BenchChibiXML < XMLBench

  def name
    'chibixml-20010306'
  end

  def parse(src)
    ChibiXML.parse src
  end

end
