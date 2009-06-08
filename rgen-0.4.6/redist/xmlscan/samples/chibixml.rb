#
# samples/chibixml.rb - xmlscan with ChibiXML
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: chibixml.rb,v 1.1 2002/09/28 10:52:41 katsu Exp $
#

require 'xmlscan/parser'
require 'chibixml'


module XMLScan

  module ChibiXML

    class Visitor

      include XMLScan::Visitor
      include ::ChibiXML

      attr_reader :document

      def on_start_document
        @document = createDocument
        @current = @document
      end

      def on_doctype(root, pubid, sysid)
        @current.doctype = Node.new(DOCUMENT_TYPE_NODE, root)
      end

      def on_comment(str)
        @current.appendChild @document.createComment(str)
      end

      def on_pi(target, pi)
        @current.appendChild @document.createProcessingInstruction(target,pi)
      end

      def on_chardata(str)
        @current.appendChild @document.createTextNode(str)
      end

      def on_entityref(ref)
        @current.appendChild @document.createEntityReference(ref)
      end

      def on_stag(name)
        element = @document.createElement(name)
        @current.appendChild element
        @current = element
      end

      def on_attribute(*)
        @attr = ''
      end

      def on_attr_value(str)
        @attr << str
      end

      def on_attr_charref(str)
        @attr << [str].pack('U')
      end

      def on_attribute_end(name)
        @current.setAttribute name, @attr
      end

      def on_etag(*)
        @current = @current.parentNode
      end

    end


    def self.parse(src)
      visitor = Visitor.new
      XMLScan::XMLParser.new(visitor).parse src
      visitor.document
    end

    def self.scan(src)
      visitor = Visitor.new
      XMLScan::XMLScanner.new(visitor).parse src
      visitor.document
    end

  end

end





if $0 == __FILE__ then
  src = ARGF
  def src.path; filename; end
  t1 = Time.times.utime
  XMLScan::ChibiXML.parse src
  t2 = Time.times.utime
  STDERR.printf "%2.3f sec\n", t2 - t1
end
