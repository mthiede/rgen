#
# xmlscan/scanner.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: scanner.rb,v 1.83 2003/05/12 14:13:33 katsu Exp $
#

#
# CONSIDERATIONS FOR CHARACTER ENCODINGS:
#
# There are the following common characteristics in character encodings
# which are supported by Ruby's $KCODE feature (ISO-8859-*, Shift_JIS,
# EUC, and UTF-8):
#
#   - Stateless.
#   - ASCII characters are encoded in the same manner as US-ASCII.
#   - The octet sequences corresponding to non-ASCII characters begin
#     with an octet greater than 0x80.
#   - The following characters can be identified by just one octet.
#     That is, every octets corresponding to the following characters in
#     US-ASCII never appear as a part of an octet sequence representing a
#     non-ASCII character.
#
#       Whitespaces("\t", "\n", "\r", and " ") and
#       ! \ " # $ % & ' ( ) * + , - . / 0 1 2 3 4 5 6 7 8 9 : ; < = > ?
#
#     Be careful that `[' and `]' are NOT included in the list!
#
# If we build a regular expression carefully in accordance with these
# characteristics, we can get the same match regardless of the value
# of $KCODE.  Moreover, if it can be premised on them, we can detect
# several delimiters without regular expressions.  XMLScanner uses this
# fact in order to share many regular expressions in all $KCODE modes,
# and in order to optimize parsing speed.
#

require 'xmlscan/visitor'


module XMLScan

  class Input

    def initialize(src)
      @src = src
      unless src.respond_to? :gets then
        if src.respond_to? :to_ary then
          @v = src.to_ary
          @n = -1
          def self.gets ; @v.at(@n += 1) ; end
          def self.lineno ; @n + 1 ; end
        else
          @v = @src
          def self.gets ; s = @v ; @v = nil ; s ; end
        end
      end
      if src.respond_to? :lineno then
        def self.lineno ; @src.lineno ; end
      end
      if src.respond_to? :path then
        def self.path ; @src.path ; end
      end
    end

    attr_reader :src

    def gets ; @src.gets ; end
    def lineno ; 0 ; end
    def path ; '-' ; end

    def self.wrap(src)
      unless src.respond_to? :gets and src.respond_to? :lineno and
          src.respond_to? :path then
        src = new(src)
      end
      src
    end

    def self.unwrap(obj)
      if self === obj then
        obj.src
      else
        obj
      end
    end

  end



  class PrivateArray < Array
    m = superclass.instance_methods(false) - Kernel.instance_methods(false)
    private(*m)
  end


  class Source < PrivateArray
    # Source inherits Array only for speed.

    def initialize(src)
      super()
      @src = Input.wrap(src)
      @eof = false
      @last = nil
    end

    def source
      Input.unwrap @src
    end


    def eof?
      @eof and empty?
    end

    def abort
      @eof = true
      @last = nil
      clear
      self
    end


    def get
      pop or
        unless @eof then
          last = @last
          begin
            src = @src.gets
            unless src then
              @eof = true
              unshift last
              last = nil
              break
            end
            a = src.split(/(?=<|>[<>])|>/n, -1)
            if last then
              unless /\A[<>]/n =~ a.first then
                a[0] = last << (a.first || '')
              else
                push last
              end
            end
            concat a
            last = pop
          end while empty?
          @last = last
          reverse!
          pop
        end
    end


    def prepare
      s = get
      s = get and s = '>' << s if s and s.empty?  # preserve first `>'
      s and push s
    end


    def tag_end?
      s = last || @last and s[0] != ?<
    end

    def tag_start?
      s = last || @last and s[0] == ?<
    end

    def close_tag               # tag_end?, and remove a `>'.
      unless s = last || @last and s[0] != ?< then
        false
      else
        if s == '>' or s.empty? then
          s1 = get
          unless s = last || @last and s[0] == ?< then  # for speed up
            out = [ s1 ]
            out.push get while s = last || @last and s == '>' || s.empty?
            out.pop unless s and s[0] != ?<    # De Morgan
            concat out
          end
        end
        true
      end
    end


    def get_text     # get until tag_start?
      s = last || @last and s[0] != ?< and get
    end

    def get_tag      # get until tag_end?
      s = last || @last and s[0] == ?< and get
    end

    def get_plain
      s = get
      s = '>' << s unless not s or (c = s[0]) == ?< or c == ?>  # De Morgan
      s
    end

    def lineno
      @src.lineno
    end

    def path
      @src.path
    end


    # The following methods are for debug.

    def inspect
      a = []
      reverse_each { |i|
        a.push ">" unless /\A[<>]/n =~ i
        a.push i.inspect
      }
      last = []
      if @last then
        last.push ">" unless /\A[<>]/n =~ @last
        last.push @last.inspect
      end
      a.push '#eof' if @eof
      "((#{a.join(' ')}) (#{last.join(' ')}) . #{source.inspect})"
    end

    def each
      prepare
      while s = get
        yield s
      end
      self
    end

    def test
      last or @last or (s = get and push s and s)
    end

  end



  class XMLScanner

    class << self

      def provided_options
        options = []
        private_instance_methods(false).each { |i|
          options.push $' if /\Aapply_option_/n =~ i
        }
        options
      end

      def apply_option(instance, option)
        instance.__send__ "apply_option_#{option}"
      end

      def apply_options(instance, options)
        h = {}
        options.each { |i| h[i.to_s] = true }
        options = h
        ancestors.each { |klass|
          if klass.respond_to? :provided_options then
            klass.provided_options.each { |i|
              if options.include? i then
                options.delete i
                klass.apply_option instance, i
              end
            }
          end
        }
        unless options.empty? then
          raise ArgumentError, "undefined option `#{options.keys[0]}'"
        end
        instance
      end
      private :apply_options

      def new(visitor, *options)
        instance = super(visitor)
        apply_options instance, options
      end

    end



    def initialize(visitor)
      @visitor = visitor
      @decoration = nil
      @src = nil
      @kcode = nil
    end


    def kcode=(kcode)
      @kcode = Regexp.new('', nil, kcode || '').kcode
      kcode
    end

    attr_reader :kcode


    def decorate(decoration)
      unless @decoration then
        @visitor = @decoration = Decoration.new(@visitor)
      end
      @decoration.expand decoration
    end
    private :decorate


    def lineno
      @src && @src.lineno
    end

    def path
      @src && @src.path
    end

    def source
      @src.source
    end


    private

    def parse_error(msg)
      @visitor.parse_error msg
    end

    def wellformed_error(msg)
      @visitor.wellformed_error msg
    end

    def valid_error(msg)
      @visitor.valid_error msg
    end

    def warning(msg)
      @visitor.warning msg
    end


    def on_xmldecl
      @visitor.on_xmldecl
    end

    def on_xmldecl_version(str)
      @visitor.on_xmldecl_version str
    end

    def on_xmldecl_encoding(str)
      @visitor.on_xmldecl_encoding str
    end

    def on_xmldecl_standalone(str)
      @visitor.on_xmldecl_standalone str
    end

    def on_xmldecl_other(name, value)
      @visitor.on_xmldecl_other name, value
    end

    def on_xmldecl_end
      @visitor.on_xmldecl_end
    end

    def on_doctype(root, pubid, sysid)
      @visitor.on_doctype root, pubid, sysid
    end

    def on_prolog_space(str)
      @visitor.on_prolog_space str
    end

    def on_comment(str)
      @visitor.on_comment str
    end

    def on_pi(target, pi)
      @visitor.on_pi target, pi
    end

    def on_chardata(str)
      @visitor.on_chardata str
    end

    def on_cdata(str)
      @visitor.on_cdata str
    end

    def on_etag(name)
      @visitor.on_etag name
    end

    def on_entityref(ref)
      @visitor.on_entityref ref
    end

    def on_charref(code)
      @visitor.on_charref code
    end

    def on_charref_hex(code)
      @visitor.on_charref_hex code
    end

    def on_start_document
      @visitor.on_start_document
    end

    def on_end_document
      @visitor.on_end_document
    end


    #  <hoge fuga="foo&bar;&#38;&#x26;foo"  />HOGE
    #  ^     ^     ^  ^    ^    ^     ^  ^  ^ ^
    #  1     2     3  4    5    6     7  8  9 A
    #
    #  The following method will be called with the following arguments
    #  when the parser reaches the above point;
    #
    #    1: on_stag              ('hoge')
    #    2: on_attribute         ('fuga')
    #    3: on_attr_value        ('foo')
    #    4: on_attr_entityref    ('bar')
    #    5: on_attr_charref      (38)
    #    6: on_attr_charref_hex  (38)
    #    7: on_attr_value        ('foo')
    #    8: on_attribute_end     ('fuga')
    #    9: on_stag_end_empty    ('hoge')
    #         or
    #       on_stag_end          ('hoge')
    #
    #    A: on_chardata          ('HOGE')

    def on_stag(name)
      @visitor.on_stag name
    end

    def on_attribute(name)
      @visitor.on_attribute name
    end

    def on_attr_value(str)
      @visitor.on_attr_value str
    end

    def on_attr_entityref(ref)
      @visitor.on_attr_entityref ref
    end

    def on_attr_charref(code)
      @visitor.on_attr_charref code
    end

    def on_attr_charref_hex(code)
      @visitor.on_attr_charref_hex code
    end

    def on_attribute_end(name)
      @visitor.on_attribute_end name
    end

    def on_stag_end_empty(name)
      @visitor.on_stag_end_empty name
    end

    def on_stag_end(name)
      @visitor.on_stag_end name
    end



    private

    module KcodeRegexp
      private
      Kcodes = [ //n.kcode, //e.kcode, //s.kcode, //u.kcode ]
      def kcode_regexp(re)
        h = {}
        Kcodes.each { |i| h[i] = Regexp.new(re, nil, i) }
        h.default = Regexp.new(re)
        h
      end
    end
    extend KcodeRegexp


    InvalidEntityRef = kcode_regexp('(?=[^#\d\w]|\z)')

    def scan_chardata(s)
      while true
        unless /&/n =~ s then
          on_chardata s
        else
          s = $`
          on_chardata s unless s.empty?
          ref = nil
          $'.split('&', -1).each { |s|
            unless /(?!\A);|(?=[ \t\r\n])/n =~ s and not $&.empty? then
              if InvalidEntityRef[@kcode] =~ s and not (ref = $`).strip.empty?
              then
                parse_error "reference to `#{ref}' doesn't end with `;'"
              else
                parse_error "`&' is not used for entity/character references"
                on_chardata('&' << s)
                next
              end
            end
            ref = $`
            s = $'
            if /\A[^#]/n =~ ref then
              on_entityref ref
            elsif /\A#(\d+)\z/n =~ ref then
              on_charref $1.to_i
            elsif /\A#x([\dA-Fa-f]+)\z/n =~ ref then
              on_charref_hex $1.hex
            else
              parse_error "invalid character reference `#{ref}'"
            end
            on_chardata s unless s.empty?
          }
        end
        s = @src.get_text
        break unless s
        s = '>' << s unless s == '>'
      end
    end


    def scan_attvalue(s)     # almostly copy & paste from scan_chardata
      unless /&/n =~ s then
        on_attr_value s
      else
        s = $`
        on_attr_value s unless s.empty?
        ref = nil
        $'.split('&', -1).each { |s|
          unless /(?!\A);|(?=[ \t\r\n])/n =~ s and not $&.empty? then
            if InvalidEntityRef[@kcode] =~ s and not (ref = $`).strip.empty?
            then
              parse_error "reference to `#{ref}' doesn't end with `;'"
            else
              parse_error "`&' is not used for entity/character references"
              on_attr_value('&' << s)
              next
            end
          end
          ref = $`
          s = $'
          if /\A[^#]/n =~ ref then
            on_attr_entityref ref
          elsif /\A#(\d+)\z/n =~ ref then
            on_attr_charref $1.to_i
          elsif /\A#x([\dA-Fa-f]+)\z/n =~ ref then
            on_attr_charref_hex $1.hex
          else
            parse_error "invalid character reference `#{ref}'"
          end
          on_attr_value s unless s.empty?
        }
      end
    end


    def scan_comment(s)
      s[0,4] = ''  # remove `<!--'
      comm = ''
      until /--/n =~ s
        comm << s
        s = @src.get_plain
        unless s then
          parse_error "unterminated comment meets EOF"
          return on_comment(comm)
        end
      end
      comm << $`
      until (s = $').empty? and @src.close_tag
        if s == '-' and @src.close_tag then      # --->
          parse_error "comment ending in `--->' is not allowed"
          comm << s
          break
        end
        parse_error "comment includes `--'"
        comm << '--'
        until /--/n =~ s     # copy & paste for performance
          comm << s
          s = @src.get_plain
          unless s then
            parse_error "unterminated comment meets EOF"
            return on_comment(comm)
          end
        end
        comm << $`
      end
      on_comment comm
    end


    def scan_pi(s)
      unless /\A<\?([^ \t\n\r?]+)(?:[ \t\n\r]+|(?=\?\z))/n =~ s then
        parse_error "parse error at `<?'"
        s << '>' if @src.close_tag
        on_chardata s
      else
        target = $1
        pi = $'
        until pi[-1] == ?? and @src.close_tag
          s = @src.get_plain
          unless s then
            parse_error "unterminated PI meets EOF"
            return on_pi(target, pi)
          end
          pi << s
        end
        pi.chop!       # remove last `?'
        on_pi target, pi
      end
    end


    CDATAPattern = kcode_regexp('\]\]\z')

    def scan_cdata(s)
      cdata = s
      re = CDATAPattern[@kcode]
      until re =~ cdata and @src.close_tag
        s = @src.get_plain
        unless s then
          parse_error "unterminated CDATA section meets EOF"
          return on_cdata(cdata)
        end
        cdata << s
      end
      cdata.chop!.chop!  # remove ']]'
      on_cdata cdata
    end


    def found_unclosed_etag(name)
      if @src.tag_start? then
        parse_error "unclosed end tag `#{name}' meets another tag"
      else
        parse_error "unclosed end tag `#{name}' meets EOF"
      end
    end

    def found_empty_etag
      parse_error "parse error at `</'"
      on_chardata '</>'
    end


    def scan_etag(s)
      s[0,2] = ''  # remove '</'
      if s.empty? then
        if @src.close_tag then   # </>
          return found_empty_etag
        else                     # </< or </[EOF]
          parse_error "parse error at `</'"
          s << '>' if @src.close_tag
          return on_chardata('</' << s)
        end
      elsif /[ \t\n\r]+/n =~ s then
        s1, s2 = $`, $'
        if s1.empty? then                # </ tag
          parse_error "parse error at `</'"
          s << '>' if @src.close_tag
          return on_chardata('</' + s)
        elsif not s2.empty? then         # </ta g
          parse_error "illegal whitespace is found within end tag `#{s1}'"
          while @src.get_tag
          end
        end
        s = s1
      end
      found_unclosed_etag s unless @src.close_tag   # </tag< or </tag[EOF]
      on_etag s
    end


    def found_empty_stag
      parse_error "parse error at `<'"
      on_chardata '<>'
    end

    def found_unclosed_stag(name)
      if @src.tag_start? then
        parse_error "unclosed start tag `#{name}' meets another tag"
      else
        parse_error "unclosed start tag `#{name}' meets EOF"
      end
    end

    def found_unclosed_emptyelem(name)
      if @src.tag_start? then
        parse_error "unclosed empty element tag `#{name}' meets another tag"
      else
        parse_error "unclosed empty element tag `#{name}' meets EOF"
      end
    end


    def found_stag_error(s)
      if /\A[\/='"]/n =~ s then
        tok, s = $&, $'
      elsif /(?=[ \t\n\r\/='"])/n =~ s then
        tok, s = $`, $'
      else
        tok, s = s, nil
      end
      parse_error "parse error at `#{tok}'"
      s
    end


    def scan_stag(s)
      unless /(?=[\/ \t\n\r='"])/n =~ s then
        name = s
        name[0,1] = ''        # remove `<'
        if name.empty? then
          if @src.close_tag then   # <>
            return found_empty_stag
          else                     # << or <[EOF]
            parse_error "parse error at `<'"
            return on_chardata('<')
          end
        end
        on_stag name
        found_unclosed_stag name unless @src.close_tag
        on_stag_end name
      else
        name = $`
        s = $'
        name[0,1] = ''        # remove `<'
        if name.empty? then   # `< tag' or `<=`
          parse_error "parse error at `<'"
          s << '>' if @src.close_tag
          return on_chardata('<' << s)
        end
        on_stag name
        emptyelem = false
        key,val,error,qmark,c = nil
        begin
          continue = false
          s.scan(/[ \t\n\r]([^= \t\n\r\/'"]+)[ \t\n\r]*=[ \t\n\r]*('[^']*'?|"[^"]*"?)|\/\z|([^ \t\n\r][\S\s]*)/n
                 ) { |key,val,error|
            if key then                # key="value"
              on_attribute key
              qmark = val.slice!(0,1)
              if val[-1] == qmark[0] then
                val.chop!
                scan_attvalue val unless val.empty?
              else
                scan_attvalue val unless val.empty?
                begin
                  s = @src.get
                  unless s then
                    parse_error "unterminated attribute `#{key}' meets EOF"
                    break
                  end
                  c = s[0]
                  val, s = s.split(qmark, 2)
                  if c == ?< then
                    wellformed_error "`<' is found in attribute `#{key}'"
                  elsif c != ?> then
                    scan_attvalue '>'
                  end
                  scan_attvalue val if c
                end until s
                continue = s      # if eof then continue is false, else true.
              end
              on_attribute_end key
            elsif error then
              continue = s = found_stag_error(error)
            else
              emptyelem = true
            end
          }
        end while continue
        unless @src.close_tag then
          if emptyelem then
            found_unclosed_emptyelem name
          else
            found_unclosed_stag name
          end
        end
        if emptyelem then
          on_stag_end_empty name
        else
          on_stag_end name
        end
      end
    end


    def scan_bang_tag(s)
      parse_error "parse error at `<!'"
      s << '>' if @src.close_tag
      on_chardata s
    end


    def scan_content(s)
      src = @src  # for speed
      while s
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
    end


    def get_until_qmark(str, qmark)
      begin
        #s = @src.get_plain
        s = @src.get
        break unless s
        c = s[0]
        v, s = s.split(qmark, 2)
        str << '>' unless c == ?< or c == ?>  # De Morgan
        str << v if c
      end until s
      s
    end


    XMLDeclPattern = kcode_regexp(%q{[ \t\n\r]([\-_\d\w]+)[ \t\n\r]*=[ \t\n\r]*('[^']*'?|"[^"]*"?)|(\?\z)|([\-_.\d\w]+|[^ \t\n\r])}) #'

    def scan_xmldecl(s)
      endmark = nil
      state = 0
      on_xmldecl
      begin
        continue = false
        s.scan(XMLDeclPattern[@kcode]) { |key,val,endmark,error|
          if key then
            qmark = val.slice!(0,1)     # remove quotation marks
            if val[-1] == qmark[0] then
              val.chop!
            else
              continue = s = get_until_qmark(val, qmark)
              unless s then
                parse_error "unterminated XML declaration meets EOF"
                endmark = true
              end
            end
            if state == 0 and key == 'version' then
              on_xmldecl_version val
              state = 1
            elsif state == 1 and key == 'encoding' then
              on_xmldecl_encoding val
              state = 2
            elsif state >= 1 and key == 'standalone' then
              on_xmldecl_standalone val
              state = 3
            else
              state = 3
              if key == 'version' then
                parse_error "version declaration must not be here"
                on_xmldecl_version val
              elsif key == 'encoding' then
                parse_error "encoding declaration must not be here"
                on_xmldecl_encoding val
                state = 2 if state < 2
              elsif key == 'standalone' then
                parse_error "standalone declaration must not be here"
                on_xmldecl_standalone val
              else
                parse_error "unknown declaration `#{key}' in XML declaration"
                on_xmldecl_other key, val
              end
            end
          elsif endmark then
            unless @src.close_tag then
              parse_error "unexpected `#{endmark}' found in XML declaration"
              endmark = nil
            end
            # here always exit the loop.
          else
            parse_error "parse error at `#{error}'"
          end
        }
      end while !endmark and continue || s = @src.get_plain
      parse_error "unterminated XML declaration meets EOF" unless s or endmark
      parse_error "no declaration found in XML declaration" if state == 0
      on_xmldecl_end
    end


    SkipDTD = kcode_regexp(%q{(['"]|\A<!--|\A<\?|--\z|\?\z)|\]\s*\z}) #'

    def skip_internal_dtd(s)
      quote = nil
      continue = true
      begin                                         # skip until `]>'
        s.scan(SkipDTD[@kcode]) { |q,|  #'
          if quote then
            quote = nil if quote == q and quote.size == 1 || @src.tag_end?
          elsif q then
            if q == '<!--' then
              quote = '--'
            elsif q == '<?' then
              quote = '?'
            elsif q == '"' or q == "'" then
              quote = q
            end
          elsif @src.close_tag then
            continue = false
          end
        }
      end while continue and s = @src.get
      parse_error "unterminated internal DTD subset meets EOF" unless s
    end


    def scan_internal_dtd(s)
      warning "internal DTD subset is not supported"
      skip_internal_dtd s
    end


    def found_invalid_pubsys(pubsys)
      parse_error "`PUBLIC' or `SYSTEM' should be here"
      'SYSTEM'
    end


    DoctypePattern = kcode_regexp(%q{[ \t\n\r](?:([^ \t\n\r\/'"=\[]+)|('[^']*'?|"[^"]*"?))|([\-_.\d\w]+|[^ \t\n\r])}) #"

    def scan_doctype(s)
      root = syspub = sysid = pubid = nil
      internal_dtd = false
      re = DoctypePattern[@kcode]
      begin
        if re =~ s then
          name, str, delim, s = $1, $2, $3, $'
          if name then
            if not root then
              root = name
            elsif not syspub then
              unless name == 'PUBLIC' or name == 'SYSTEM' then
                name = found_invalid_pubsys(name)
              end
              syspub = name
            else
              parse_error "parse error at `#{name}'"
            end
          elsif str then
            qmark = str.slice!(0,1)     # remove quotation marks
            unless syspub then
              parse_error "parse error at `#{qmark}'"
              s = str << s
            else
              if str[-1] == qmark[0] then
                str.chop!
              else
                s = get_until_qmark(str, qmark) || ''
              end
              if not sysid then
                sysid = str
              elsif not pubid and syspub == 'PUBLIC' then
                pubid = sysid
                sysid = str
              else
                parse_error "too many external ID literals in DOCTYPE"
              end
            end
          elsif delim == '[' then
            internal_dtd = true
            break
          else
            parse_error "parse error at `#{delim}'"
          end
        else
          s = ''
        end
        if s.empty? then
          break if @src.close_tag
          s = @src.get_plain
        end
      end while s
      parse_error "unterminated DOCTYPE declaration meets EOF" unless s
      unless root then
        parse_error "no root element is specified in DOCTYPE"
      end
      if syspub and not sysid then
        parse_error "too few external ID literals in DOCTYPE"
      end
      if syspub == 'PUBLIC' and not pubid then
        pubid, sysid = sysid, nil
      end
      on_doctype root, pubid, sysid
      scan_internal_dtd s if internal_dtd
    end


    def scan_prolog(s)
      if /\A<\?xml(?=[ \t\n\r])/n =~ s then
        scan_xmldecl $'
        s = @src.get
      end
      doctype = true
      src = @src  # for speed
      while s
        if s[0] == ?< then
          if (c = s[1]) == ?! then
            if s[2] == ?- and s[3] == ?- then
              scan_comment s
            elsif /\A<!DOCTYPE(?=[ \t\n\r])/n =~ s and doctype then
              doctype = false
              scan_doctype $'
            else
              break
            end
          elsif c == ?? then
            scan_pi s
          else
            break
          end
          s = src.get
        elsif /[^ \t\r\n]/ !~ s then
          on_prolog_space s unless s.empty?
          s = src.get_plain
        else
          break
        end
      end
      scan_content(s || src.get)
    end


    def scan_document
      on_start_document
      @src.prepare
      scan_prolog @src.get
      on_end_document
    end


    def make_source(src)
      Source.new src
    end


    public

    def parse_document(src)
      @src = make_source(src)
      begin
        scan_document
      ensure
        @src = nil
      end
      self
    end

    alias parse parse_document

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
  end

  $s = scan = XMLScan::XMLScanner.new(TestVisitor.new)
  src = ARGF
  def src.path; filename; end
  t1 = Time.times.utime
  scan.parse src
  t2 = Time.times.utime
  STDERR.printf "%2.3f sec\n", t2 - t1
end
