#
# samples/xmlbench/parser/nqxml.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: nqxml.rb,v 1.1 2002/12/26 17:32:46 katsu Exp $
#

require 'nqxml/streamingparser'
require 'nqxml/treeparser'


class BenchNQXMLStream < XMLBench

  def name
    'NQXML::StreamingParser'
  end

  def parse(src)
    parser = NQXML::StreamingParser.new(src)
    parser.instance_eval {
      @tokenizer.instance_eval {
        @internalEntities.default = ''
      }
    }
    parser.each { }
  end

end
