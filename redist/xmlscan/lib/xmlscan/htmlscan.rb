#
# xmlscan/htmlscan.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: htmlscan.rb,v 1.18 2003/05/01 15:36:50 katsu Exp $
#

require 'xmlscan/scanner'


module XMLScan

  class HTMLScanner < XMLScanner

    private

    def wellformed_error(msg)
      # All wellformed error raised by XMLScanner are ignored.
      # XMLScanner only raises wellformed error in stan_stag, which is a
      # method completely overrided by HTMLScanner, so this method is
      # never called in fact.
    end

    def on_xmldecl
      raise "[BUG] this method must be never called"
    end

    def on_xmldecl_version(str)
      raise "[BUG] this method must be never called"
    end

    def on_xmldecl_encoding(str)
      raise "[BUG] this method must be never called"
    end

    def on_xmldecl_standalone(str)
      raise "[BUG] this method must be never called"
    end

    def on_xmldecl_other(name, value)
      raise "[BUG] this method must be never called"
    end

    def on_xmldecl_end
      raise "[BUG] this method must be never called"
    end

    def on_stag_end_empty(name)
      raise "[BUG] this method must be never called"
    end


    private

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
      s = $'
      until s.empty? || s.strip.empty? and @src.close_tag   # --> or -- >
        comm << '--'
        if /\A\s*--/n =~ s then   # <!--hoge-- --
          comm << $&
          s = $'
          if s.empty? and @src.close_tag then   # <!--hoge-- -->
            parse_error "`-->' is found but comment must not end here"
            comm.chop!.chop!
            break
          end
        else                     # <!--hoge-- fuga
          parse_error "only whitespace can appear between two comments"
        end
        if /\A-\s*\z/n =~ s and @src.close_tag then  # <!--hoge--->
          parse_error "`-->' is found but comment must not end here"
          comm.chop!
          break
        end
        until /--/n =~ s      # copy & paste for performance
          comm << s
          s = @src.get_plain
          unless s then
            parse_error "unterminated comment meets EOF"
            return on_comment(comm)
          end
        end
        comm << $`
        s = $'
      end
      on_comment comm
    end


    alias scan_xml_pi  scan_pi    # PIO "<?" PIC "?>"  -- <? PI ?> --


    def scan_pi(s)   # <?PI >  this is default in SGML.
      s[0,2] = ''    # remove `<?'
      pi = s
      until @src.close_tag
        s = @src.get_plain
        unless s then
          parse_error "unterminated PI meets EOF"
          break
        end
        pi << s
      end
      on_pi '', pi
    end


    def scan_stag(s)
      unless /(?=[\/\s='"])/n =~ s then
        name = s
        name[0,1] = ''        # remove `<'
        if name.empty? then   # <> or <<
          if @src.close_tag then
            return found_empty_stag
          else
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
          if @src.close_tag then
            s << '>'
          end
          return on_chardata('<' << s)
        end
        on_stag name
        begin
          continue = false
          s.scan(
         /([^\s=\/'"]+)(?:\s*=\s*(?:('[^']*'?|"[^"]*"?)|([^\s='"]+)))?|(\S)/n
                 ) { |key,val,val2,error|
            if key then
              if val then                # key="value"
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
                    scan_attvalue '>' unless c == ?< or c == ?>
                    scan_attvalue val if c
                  end until s
                  continue = s
                end
                on_attribute_end key
              elsif val2 then            # key=value
                on_attribute key
                on_attr_value val2
                on_attribute_end key
              else                       # value
                on_attribute nil
                on_attr_value key
                on_attribute_end nil
              end
            else
              parse_error "parse error at `#{error}'"
            end
          }
        end while continue
        found_unclosed_stag name unless @src.close_tag
        on_stag_end name
      end
    end


    # This method should be called only from on_stag_end.
    def get_cdata_content
      unless not s = @src.test or s[0] == ?< && s[1] == ?/ then
        dst = @src.get
        until not s = @src.test or s[0] == ?< && s[1] == ?/
          dst << @src.get_plain
        end
        dst
      else
        ''
      end
    end
    public :get_cdata_content


    def scan_bang_tag(s)
      if s == '<!' and @src.close_tag then    # <!>
        on_comment ''
      else
        parse_error "parse error at `<!'"
        while s and not @src.close_tag        # skip entire
          s = @src.get_plain
        end
      end
    end


    def scan_internal_dtd(s)
      parse_error "DTD subset is found but it is not permitted in HTML"
      skip_internal_dtd s
    end


    def found_invalid_pubsys(pubsys)
      s = pubsys.upcase
      return s if s == 'PUBLIC' or s == 'SYSTEM'
      super
    end


    def scan_prolog(s)
      doctype = 0
      while s
        if s[0] == ?< then
          if (c = s[1]) == ?! then
            if s[2] == ?- and s[3] == ?- then
              scan_comment s
            elsif /\A<!doctype(?=\s)/in =~ s then
              doctype += 1
              if doctype > 1 then
                parse_error "another document type declaration is found"
              end
              scan_doctype $'
            else
              break
            end
          elsif c == ?? then
            scan_pi s
          else
            break
          end
        elsif s.strip.empty? then
          on_prolog_space s
        else
          break
        end
        s = @src.get
      end
      scan_content(s || @src.get)
    end

  end

end





if $0 == __FILE__ then
  class TestVisitor
    include XMLScan::Visitor
    def parse_error(msg)
      STDERR.printf("%s:%d: %s\n", $s.path, $s.lineno, msg) if $VERBOSE
    end
  end

  $s = scan = XMLScan::HTMLScanner.new(TestVisitor.new)
  src = ARGF
  def src.path; filename; end
  t1 = Time.times.utime
  scan.parse src
  t2 = Time.times.utime
  STDERR.printf "%2.3f sec\n", t2 - t1
end
