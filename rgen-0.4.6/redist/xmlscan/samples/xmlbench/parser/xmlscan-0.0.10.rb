#
# samples/xmlbench/parser/xmlscan-0.0.10.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlscan-0.0.10.rb,v 1.1 2002/12/26 17:32:46 katsu Exp $
#

require 'xmlscan'


class BenchXMLScan0010 < XMLBench

  class Scanner < XMLScanner
    def entityref_literal(ref)  ''  end
  end

  def name
    'xmlscan-0.0.10 XMLScanner'
  end

  def parse(src)
    Scanner.new.parse src
  end

end



class BenchXMLScan0010Parser < XMLBench

  class Scanner < WellFormedXMLScanner
    def entityref_literal(ref)  ''  end
  end

  def name
    'xmlscan-0.0.10 WellFormed'
  end

  def parse(src)
    Scanner.new.parse src
  end

end



class BenchXMLScan0010ParserNamespace < XMLBench

  class Scanner < XMLScannerWithNamespace
    def entityref_literal(ref)  ''  end
  end

  def name
    'xmlscan-0.0.10 Namespace'
  end

  def parse(src)
    Scanner.new.parse src
  end

end
