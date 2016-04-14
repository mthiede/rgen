# RGen Framework
# (c) Martin Thiede, 2006

module RGen
  
module TemplateLanguage
  
  class OutputHandler
    attr_accessor :noIndentNextLine
    
    def initialize(indent=0, indentString="   ", mode=:explicit)
      self.mode = mode
      @indentString = indentString
      @state = :wait_for_nonws
      @output = ""
      @indent_string = @indentString*indent
    end

    def indent=(i)
      @indent_string = @indentString*i
    end

    NL = "\n"
    LFNL = "\r\n"
    if RUBY_VERSION.start_with?("1.8")
      NL_CHAR = 10
      LF_CHAR = 13
    else
      NL_CHAR = "\n"
      LF_CHAR = "\r"
    end
    
    # ERB will call this method for every string s which is part of the
    # template file in between %> and <%. If s contains a newline, it will
    # call this method for every part of s which is terminated by a \n
    # 
    def concat(s)
      if @ignoreNextNL
        idx = s.index(NL)
        if idx && s[0..idx].strip.empty?
          s = s[idx+1..-1]
        end
        @ignoreNextNL = false unless s.strip.empty?
      end
      if @ignoreNextWS
        s = s.lstrip
        @ignoreNextWS = false unless s.empty?
      end
      if @mode == :direct
        @output.concat(s)
      elsif @mode == :explicit
        while s.size > 0
          if @state == :wait_for_nl
            idx = s.index(NL)
            if idx
              if s[idx-1] == LF_CHAR
                @output.concat(s[0..idx].rstrip)
                @output.concat(LFNL)
              else
                @output.concat(s[0..idx].rstrip)
                @output.concat(NL)
              end
              s = s[idx+1..-1]
              @state = :wait_for_nonws
            else
              @output.concat(s)
              break
            end
          elsif @state == :wait_for_nonws
            s = s.lstrip
            if !s.empty?
              unless @noIndentNextLine || (@output[-1] && @output[-1] != NL_CHAR)
                @output.concat(@indent_string)
              else
                @noIndentNextLine = false
              end
              @state = :wait_for_nl
            end
          end
        end
      end
    end
    alias << concat
    
    def to_str
      @output
    end
    alias to_s to_str
    
    def direct_concat(s)
      @output.concat(s)
    end
    
    def direct_concat_allow_indent(s)
      unless @noIndentNextLine || (@output[-1] && @output[-1] != NL_CHAR)
        @output.concat(@indent_string)
      else
        @noIndentNextLine = false
      end
      @state = :wait_for_nl
      @output.concat(s)
    end

    def ignoreNextNL
      @ignoreNextNL = true
    end
    
    def ignoreNextWS
      @ignoreNextWS = true
    end
    
    def mode=(m)
      raise StandardError.new("Unknown mode: #{m}") unless [:direct, :explicit].include?(m)
      @mode = m
    end
  end
  
end
  
end
