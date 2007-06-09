#
# samples/xmlbench/parser/rexml.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: rexml.rb,v 1.2 2003/03/16 02:38:02 katsu Exp $
#

require 'rexml/document'
require 'rexml/streamlistener'
require 'rexml/pullparser'


class BenchREXMLStream < XMLBench

  class REXMLListener
    include REXML::StreamListener
  end

  def name
    'REXML::Document.parse_stream'
  end

  def parse(src)
    s = REXML::SourceFactory.create_from(src)
    REXML::Document.parse_stream s, REXMLListener.new
  end

end


class BenchREXMLTree < XMLBench

  class REXMLListener
    include REXML::StreamListener
  end

  def name
    'REXML::Document.new'
  end

  def parse(src)
    REXML::Document.new src
  end

end


class BenchREXMLPull < XMLBench

  def name
    'REXML::PullParser'
  end

  def parse(src)
    parser = REXML::PullParser.new(src)
    until parser.empty?
      parser.next
    end
  end

end
