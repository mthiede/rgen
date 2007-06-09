#
# xmlscan/parser.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: parser.rb,v 1.10 2003/01/22 13:06:18 katsu Exp $
#

require 'xmlscan/scanner'


module XMLScan

  class XMLParser < XMLScanner

    class AttributeChecker < Hash
      # AttributeChecker inherits Hash only for speed.

      def check_unique(name)
        not key? name and store(name, true)
      end

    end


    #PredefinedEntity = {
    #  'lt'   => '<',
    #  'gt'   => '>',
    #  'amp'  => '&',
    #  'quot' => '"',
    #  'apos' => "'",
    #}


    def parse(*)
      @elem = []
      @attr = AttributeChecker.new
      @standalone = nil
      super
    end


    private

    def on_xmldecl_version(str)
      unless str == '1.0' then
        warning "unsupported XML version `#{str}'"
      end
      @visitor.on_xmldecl_version str
    end


    def on_xmldecl_standalone(str)
      if str == 'yes' then
        @standalone = true
      elsif str == 'no' then
        @standalone = false
      else
        parse_error "standalone declaration must be either `yes' or `no'"
      end
      @visitor.on_xmldecl_standalone str
    end


    def on_doctype(name, pubid, sysid)
      if pubid and not sysid then
        parse_error "public external ID must have both public ID and system ID"
      end
      @visitor.on_doctype name, pubid, sysid
    end


    def on_prolog_space(s)
      # just ignore it.
    end


    def on_pi(target, pi)
      if target.downcase == 'xml' then
        parse_error "reserved PI target `#{target}'"
      end
      @visitor.on_pi target, pi
    end


    #def on_entityref(ref)
    #  rep = PredefinedEntity[ref]
    #  if rep then
    #    @visitor.on_chardata rep
    #  else
    #    @visitor.on_entityref ref
    #  end
    #end


    #def on_attr_entityref(ref)
    #  rep = PredefinedEntity[ref]
    #  if rep then
    #    @visitor.on_attr_value rep
    #  else
    #    @visitor.on_attr_entityref ref
    #  end
    #end


    #def on_charref_hex(code)
    #  on_charref code
    #end


    #def on_attr_charref_hex(code)
    #  on_attr_charref code
    #end


    def on_stag(name)
      @elem.push name
      @visitor.on_stag name
      @attr.clear
    end

    def on_attribute(name)
      unless @attr.check_unique name then
        wellformed_error "doubled attribute `#{name}'"
      end
      @visitor.on_attribute name
    end

    def on_attr_value(str)
      str.tr! "\t\r\n", ' '   # normalize
      @visitor.on_attr_value str
    end

    def on_stag_end_empty(name)
      # @visitor.on_stag_end name
      # @elem.pop
      # @visitor.on_etag name
      @visitor.on_stag_end_empty name
      @elem.pop
    end

    def on_etag(name)
      last = @elem.pop
      if last == name then
        @visitor.on_etag name
      elsif last then
        wellformed_error "element type `#{name}' is not matched"
        @visitor.on_etag last
      else
        parse_error "end tag `#{name}' appears alone"
      end
    end


    public


    def scan_content(s)
      elem = @elem  # for speed
      src = @src  # for speed
      found_root_element = false

      begin

        # -- first start tag --
        elem.clear
        found_stag = false

        while s and not found_stag
          if (c = s[0]) == ?< then
            if (c = s[1]) == ?/ then
              # should be a parse error
              scan_etag s
            elsif c == ?! then
              if s[2] == ?- and s[3] == ?- then
                scan_comment s
              elsif /\A<!\[CDATA\[/n =~ s then
                parse_error "CDATA section is found outside of root element"
                scan_cdata $'
              else
                scan_bang_tag s
              end
            elsif c == ?? then
              scan_pi s
            else
              found_root_element = true
              found_stag = true
              scan_stag s
            end
          else
            parse_error "content of element is found outside of root element"
            scan_chardata s
          end
          s = src.get
        end

        if not found_root_element and not found_stag then
          parse_error "no root element was found"
        end

        # -- contents --
        while s and not elem.empty?
          if (c = s[0]) == ?< then
            if (c = s[1]) == ?/ then
              scan_etag s
            elsif c == ?! then
              if s[2] == ?- and s[3] == ?- then
                scan_comment s
              elsif /\A<!\[CDATA\[/n =~ s then
                scan_cdata $'
              else
                scan_bang_tag s
              end
            elsif c == ?? then
              scan_pi s
            else
              scan_stag s
            end
          else
            scan_chardata s
          end
          s = src.get
        end

        unless elem.empty? then
          while name = elem.pop
            parse_error "unclosed element `#{name}' meets EOF"
            @visitor.on_etag name
          end
        end

        # -- epilogue --
        finish = true

        while s
          if (c = s[0]) == ?< then
            if (c = s[1]) == ?/ then
              finish = false    # content out of root element
              break
            elsif c == ?! then
              if s[2] == ?- and s[3] == ?- then
                scan_comment s
              else
                finish = false  # content out of root element
                break
              end
            elsif c == ?? then
              scan_pi s
            else
              parse_error "another root element is found"  # stag
              finish = false
              break
            end
          else
            if s.strip.empty? then
              on_prolog_space s
            else
              finish = false    # content out of root element
              break
            end
          end
          s = src.get
        end

      end until finish

    end
  end


end






if $0 == __FILE__ then
  class TestVisitor
    include XMLScan::Visitor
    def parse_error(msg)
      STDERR.printf("%s:%d: %s\n", $s.path, $s.lineno, msg) if $VERBOSE
    end
    def wellformed_error(msg)
      STDERR.printf("%s:%d: WFC: %s\n", $s.path, $s.lineno, msg) if $VERBOSE
    end
    def warning(msg)
      STDERR.printf("%s:%d: warning: %s\n", $s.path,$s.lineno, msg) if $VERBOSE
    end
  end

  $s = scan = XMLScan::XMLParser.new(TestVisitor.new)
  src = ARGF
  def src.path; filename; end
  t1 = Time.times.utime
  scan.parse src
  t2 = Time.times.utime
  STDERR.printf "%2.3f sec\n", t2 - t1
end
