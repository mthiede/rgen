#
# samples/rexml.rb - xmlscan with REXML
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: rexml.rb,v 1.1 2002/09/29 15:55:31 katsu Exp $
#

require 'xmlscan/parser'
require 'rexml/document'


module XMLScan

  module REXML

    class Visitor

      include XMLScan::Visitor
      include ::REXML

      def initialize(context = {})
        @document = Document.new(nil, context)
      end

      attr_reader :document


      def on_start_document
        @current = @document
      end


      def on_xmldecl
        @version = nil
        @encoding = nil
        @standalone = nil
      end

      def on_xmldecl_version(str)
        @version = str
      end

      def on_xmldecl_encoding(str)
        @encoding = str
      end

      def on_xmldecl_standalone(str)
        @standalone = str
      end

      def on_xmldecl_end
        @document.add XMLDecl.new(@version, @encoding, @standalone)
      end


      def on_doctype(root, pubid, sysid)
        if pubid then
          external_id = 'PUBLIC'
        else
          external_id = 'SYSTEM'
        end
        if pubid then
          if /"/ =~ pubid then
            external_id <<  " '#{pubid}'"
          else
            external_id << %' "#{pubid}"'
          end
        end
        if sysid then
          if /"/ =~ sysid then
            external_id <<  " '#{sysid}'"
          else
            external_id << %' "#{sysid}"'
          end
        end
        @current.add DocType.new(root, external_id)
      end


      def on_comment(str)
        @current.add Comment.new(str)
      end

      def on_pi(target, pi)
        @current.add Instruction.new(target, pi)
      end


      def on_stag(name)
        @current = Element.new(name, @current, @current.context)
      end

      def on_attribute(name)
        @attr = ''
      end

      def on_attr_value(str)
        @attr << str
      end

      def on_attr_entityref(ref)
        @attr << "&#{ref};"
      end

      def on_attr_charref(code)
        @attr << [code].pack('U')
      end

      def on_attribute_end(name)
        @current.add_attribute name, @attr
      end

      def on_etag(name)
        @current = @current.parent
      end


      def on_chardata(str)
        @current.add_text str
      end

      def on_cdata(str)
        @current.add CData.new(str)
      end

      def on_entityref(ref)
        @current.add_text "&#{ref};"
      end

      def on_charref(code)
        @current.add_text "&#{code};"
      end

    end


    def self.parse(src)
      visitor = Visitor.new
      XMLScan::XMLParser.new(visitor).parse src
      visitor.document
    end

  end

end





if $0 == __FILE__ then
  src = ARGF
  def src.path; filename; end
  t1 = Time.times.utime
  XMLScan::REXML.parse src
  t2 = Time.times.utime
  STDERR.printf "%2.3f sec\n", t2 - t1
end
