#
# xmlscan/visitor.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: visitor.rb,v 1.3 2003/05/12 14:13:33 katsu Exp $
#

require 'xmlscan/version'


module XMLScan

  class Error < StandardError

    def initialize(msg, path = nil, lineno = nil)
      super msg
      @path = path
      @lineno = lineno
    end

    attr_reader :path, :lineno

    def to_s
      if @lineno and @path then
        "#{@path}:#{@lineno}:#{super}"
      else
        super
      end
    end

  end

  class ParseError < Error ; end
  class NotWellFormedError < Error ; end
  class NotValidError < Error ; end


  module Visitor

    def parse_error(msg)
      raise ParseError.new(msg)
    end

    def wellformed_error(msg)
      raise NotWellFormedError.new(msg)
    end

    def valid_error(msg)
      raise NotValidError.new(msg)
    end

    def warning(msg)
    end

    def on_xmldecl
    end

    def on_xmldecl_version(str)
    end

    def on_xmldecl_encoding(str)
    end

    def on_xmldecl_standalone(str)
    end

    def on_xmldecl_other(name, value)
    end

    def on_xmldecl_end
    end

    def on_doctype(root, pubid, sysid)
    end

    def on_prolog_space(str)
    end

    def on_comment(str)
    end

    def on_pi(target, pi)
    end

    def on_chardata(str)
    end

    def on_cdata(str)
    end

    def on_etag(name)
    end

    def on_entityref(ref)
    end

    def on_charref(code)
    end

    def on_charref_hex(code)
    end

    def on_start_document
    end

    def on_end_document
    end

    def on_stag(name)
    end

    def on_attribute(name)
    end

    def on_attr_value(str)
    end

    def on_attr_entityref(ref)
    end

    def on_attr_charref(code)
    end

    def on_attr_charref_hex(code)
    end

    def on_attribute_end(name)
    end

    def on_stag_end_empty(name)
    end

    def on_stag_end(name)
    end

  end


  class Decoration

    include Visitor

    def initialize(visitor)
      @visitor = visitor
    end

    Visitor.instance_methods(false).each { |i|
      module_eval <<-END, __FILE__, __LINE__ + 1
        def #{i}(*args)
          @visitor.#{i}(*args)
        end
      END
    }

  end

end
