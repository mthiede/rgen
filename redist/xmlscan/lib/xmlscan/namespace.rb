#
# xmlscan/namespace.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: namespace.rb,v 1.13 2003/01/22 13:06:18 katsu Exp $
#

require 'xmlscan/parser'


module XMLScan

  class NSParseError < ParseError ; end
  class NSNotWellFormedError < NotWellFormedError ; end
  class NSNotValidError < NotValidError ; end


  module NSVisitor

    include Visitor

    def ns_parse_error(msg)
      raise NSParseError.new(msg)
    end

    def ns_wellformed_error(msg)
      raise NSNotWellFormedError.new(msg)
    end

    def ns_valid_error(msg)
      raise NSNotValidError.new(msg)
    end

    #
    # <foo:bar hoge:fuga='' hoge=''  >
    # <foo     hoge:fuga='' hoge=''  >
    #  ^       ^          ^ ^     ^  ^
    #  1       2          3 4     5  6
    #
    #  The following method will be called with the following arguments
    #  when the parser reaches the above point;
    #
    #    1: on_stag_ns           ('foo:bar', 'foo', 'bar')
    #        or
    #       on_stag_ns           ('foo', '', 'foo')
    #    2: on_attribute_ns      ('hoge:fuga', 'hoge', 'fuga')
    #    3: on_attribute_end     ('hoge:fuga')
    #    4: on_attribute_ns      ('hoge', nil, 'hoge')
    #    5: on_attribute_end     ('hoge')
    #    6: on_stag_end_ns       ('foo:bar', { 'foo' => '', ... })
    #        or
    #       on_stag_end_empty_ns ('foo:bar', { 'foo' => '', ... })
    #

    def on_stag_ns(qname, prefix, localpart)
    end

    def on_attribute_ns(qname, prefix, localpart)
    end

    def on_stag_end_ns(qname, namespaces)
    end

    def on_stag_end_empty_ns(qname, namespaces)
    end

  end




  class XMLNamespaceDecoration < Decoration

    proc {
      h = {'foo'=>true} ; h['foo'] = nil
      raise "requires Ruby-1.6 or above" unless h.key? 'foo'
    }.call

    PredefinedNamespace = {
      'xml'   => 'http://www.w3.org/XML/1998/namespace',
      'xmlns' => 'http://www.w3.org/2000/xmlns/',
    }

    ReservedNamespace = PredefinedNamespace.invert


    def ns_parse_error(msg)
      @orig_visitor.ns_parse_error msg
    end

    def ns_wellformed_error(msg)
      @orig_visitor.ns_wellformed_error msg
    end

    def ns_valid_error(msg)
      @orig_visitor.ns_valid_error msg
    end


    def on_start_document
      @namespace = {} #PredefinedNamespace.dup
      @ns_hist = []
      @ns_undeclared = {}     # for checking undeclared namespace prefixes.
      @prev_prefix = {}       # for checking doubled attributes.
      @dont_same = []         # ditto.
      @xmlns = NamespaceDeclaration.new(self)
      @orig_visitor = @visitor
      @visitor.on_start_document
    end


    def on_stag(name)
      @ns_hist.push nil
      unless /:/n =~ name then
        @visitor.on_stag_ns name, '', name
      else
        prefix, localpart = $`, $'
        if localpart.include? ?: then
          ns_parse_error "localpart `#{localpart}' includes `:'"
        end
        if prefix == 'xmlns' then
          ns_wellformed_error \
            "prefix `xmlns' is not used for namespace prefix declaration"
        end
        unless @namespace.key? prefix then
          if uri = PredefinedNamespace[prefix] then
            @namespace[prefix] = uri
          else
            @ns_undeclared[prefix] = true
          end
        end
        @visitor.on_stag_ns name, prefix, localpart
      end
    end


    def on_attribute(name)
      if /:/n =~ name then
        prefix, localpart = $`, $'
        if localpart.include? ?: then
          ns_parse_error "localpart `#{localpart}' includes `:'"
        end
        unless @namespace.key? prefix then
          if uri = PredefinedNamespace[prefix] then
            @namespace[prefix] = uri
          else
            @ns_undeclared[prefix] = true
          end
        end
        if prefix == 'xmlns' then
          @visitor = @xmlns
          @xmlns.on_xmlns_start localpart
        else
          if prev = @prev_prefix[localpart] then
            @dont_same.push [ prev, prefix, localpart ]
          end
          @prev_prefix[localpart] = prefix
          @visitor.on_attribute_ns name, prefix, localpart
        end
      elsif name == 'xmlns' then
        @visitor = @xmlns
        @xmlns.on_xmlns_start ''
      else
        @visitor.on_attribute_ns name, nil, name
      end
    end


    class NamespaceDeclaration

      include XMLScan::Visitor

      def initialize(parent)
        @parent = parent
      end

      def on_xmlns_start(prefix)
        @prefix = prefix
        @nsdecl = ''
      end

      def on_attr_value(str)
        @nsdecl << str
      end

      def on_attr_entityref(ref)
        @parent.ns_wellformed_error \
          "xmlns includes undeclared entity reference"
      end

      def on_attr_charref(code)
        @nsdecl << [code].pack('U')
      end

      def on_attr_charref_hex(code)
        @nsdecl << [code].pack('U')
      end

      def on_attribute_end(name)
        @parent.on_xmlns_end @prefix, @nsdecl
      end

    end


    def on_xmlns_end(prefix, uri)
      @visitor = @orig_visitor
      if PredefinedNamespace.key? prefix then
        if prefix == 'xmlns' then
          ns_wellformed_error \
            "prefix `xmlns' can't be bound to any namespace explicitly"
        elsif (s = PredefinedNamespace[prefix]) != uri then
          ns_wellformed_error \
            "prefix `#{prefix}' can't be bound to any namespace except `#{s}'"
        end
      end
      if uri.empty? then
        if prefix.empty? then
          uri = nil
        else
          ns_parse_error "`#{prefix}' is bound to empty namespace name"
        end
      elsif ReservedNamespace.key? uri then
        unless (s = ReservedNamespace[uri]) == prefix then
          ns_wellformed_error \
            "namespace `#{uri}' is reserved for prefix `#{s}'"
        end
      end
      (@ns_hist.last || @ns_hist[-1] = {})[prefix] = @namespace[prefix]
      @namespace[prefix] = uri
      @ns_undeclared.delete prefix
    end


    def fix_namespace
      unless @ns_undeclared.empty? then
        @ns_undeclared.each_key { |i|
          @visitor.ns_wellformed_error "prefix `#{i}' is not declared"
        }
        @ns_undeclared.clear
      end
      unless @dont_same.empty? then
        @dont_same.each { |n1,n2,l|
          if @namespace[n1] == @namespace[n2] then
            ns_wellformed_error \
              "doubled localpart `#{l}' in the same namespace"
          end
        }
        @dont_same.clear
      end
      @prev_prefix.clear
    end


    def on_stag_end(name)
      fix_namespace
      @visitor.on_stag_end_ns name, @namespace
    end


    def on_etag(name)
      h = @ns_hist.pop and @namespace.update h
      @visitor.on_etag name
    end


    def on_stag_end_empty(name)
      fix_namespace
      @visitor.on_stag_end_empty_ns name, @namespace
      h = @ns_hist.pop and @namespace.update h
    end


    def on_doctype(root, pubid, sysid)
      if root.count(':') > 1 then
        ns_parse_error "qualified name `#{root}' includes `:'"
      end
      @visitor.on_doctype root, pubid, sysid
    end


    def on_pi(target, pi)
      if target.include? ?: then
        ns_parse_error "PI target `#{target}' includes `:'"
      end
      @visitor.on_pi target, pi
    end


    def on_entityref(ref)
      if ref.include? ?: then
        ns_parse_error "entity reference `#{ref}' includes `:'"
      end
      @visitor.on_entityref ref
    end


    def on_attr_entityref(ref)
      if ref.include? ?: then
        ns_parse_error "entity reference `#{ref}' includes `:'"
      end
      @visitor.on_attr_entityref ref
    end

  end



  class XMLParserNS < XMLParser

    def initialize(*)
      super
      @visitor = @decoration = XMLNamespaceDecoration.new(@visitor)
    end

  end

end





if $0 == __FILE__ then
  class TestVisitor
    include XMLScan::NSVisitor
    def parse_error(msg)
      STDERR.printf("%s:%d: %s\n", $s.path, $s.lineno, msg) if $VERBOSE
    end
    def wellformed_error(msg)
      STDERR.printf("%s:%d: WFC: %s\n", $s.path, $s.lineno, msg) if $VERBOSE
    end
    def warning(msg)
      STDERR.printf("%s:%d: warning: %s\n", $s.path,$s.lineno, msg) if $VERBOSE
    end
    def ns_parse_error(msg)
      STDERR.printf("%s:%d: %s\n", $s.path, $s.lineno, msg) if $VERBOSE
    end
    def ns_wellformed_error(msg)
      STDERR.printf("%s:%d: NSC: %s\n", $s.path, $s.lineno, msg) if $VERBOSE
    end
  end

  $s = scan = XMLScan::XMLParserNS.new(TestVisitor.new)
  src = ARGF
  def src.path; filename; end
  t1 = Time.times.utime
  scan.parse src
  t2 = Time.times.utime
  STDERR.printf "%2.3f sec\n", t2 - t1
end
