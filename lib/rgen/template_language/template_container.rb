# RGen Framework
# (c) Martin Thiede, 2006

require 'erb'
require 'fileutils'
require 'rgen/template_language/output_handler'
require 'rgen/template_language/template_helper'

module RGen
  
module TemplateLanguage
  
class TemplateContainer
  include TemplateHelper
  
  def initialize(metamodels, output_path, parent, filename)
    @templates = {}
    @parent = parent
    @filename = filename
    @indent = 0
    @output_path = output_path
    @metamodels = metamodels
    @metamodels = [ @metamodels ] unless @metamodels.is_a?(Array)
  end
  
  def load
    File.open(@filename) do |f|
      begin
        @@metamodels = @metamodels
        fileContent = f.read
        _detectNewLinePattern(fileContent)
        ERB.new(fileContent,nil,nil,'@output').result(binding)
      rescue Exception => e
        processAndRaise(e)
      end
    end
  end
  
  # if this container can handle the call, the expansion result is returned
  # otherwise expand is called on the appropriate container and the result is added to @output
  def expand(template, *all_args)
    args, params = _splitArgsAndOptions(all_args)
    if params.has_key?(:foreach)
      raise StandardError.new("expand :foreach argument is not enumerable") \
        unless params[:foreach].is_a?(Enumerable)
      _expand_foreach(template, args, params)
    else
      _expand(template, args, params)
    end
  end
  
  def this
    @context
  end
  
  def method_missing(name, *args)
    @context.send(name, *args)
  end
  
  def self.const_missing(name)
    super unless @@metamodels
    @@metamodels.each do |mm|
      return mm.const_get(name) rescue NameError
    end
    super
  end
  
  private
  
  def nonl
    @output.ignoreNextNL
  end
  
  def nows
    @output.ignoreNextWS
  end
  
  def nl
    _direct_concat(@newLinePattern)
  end
  
  def ws
    _direct_concat(" ")
  end
  
  def iinc
    @indent += 1
    @output.indent = @indent
  end
  
  def idec
    @indent -= 1 if @indent > 0
    @output.indent = @indent
  end
  
  def define(template, params={}, &block)
    @templates[template] ||= {}
    cls = params[:for] || Object
    @templates[template][cls] = block
  end
  
  def file(name, indentString=nil)
    old_output, @output = @output, OutputHandler.new(@indent, indentString || @parent.indentString)
    begin
      yield
    rescue Exception => e
      processAndRaise(e)
    end
    path = ""
    path += @output_path+"/" if @output_path
    dirname = File.dirname(path+name)
    FileUtils.makedirs(dirname) unless File.exist?(dirname)
    File.open(path+name,"w") { |f| f.write(@output) }
    @output = old_output
  end
  
  # private private
  
  def _expand_foreach(template, args, params)
    sep = params[:separator]
    params[:foreach].each_with_index {|e,i|
      single_params = params.dup
      single_params[:for] = e
      _direct_concat(sep.to_s) if sep && i > 0 
      _expand(template, args, single_params)
    }
  end
  
  LOCAL_TEMPLATE_REGEX = /^:*(\w+)$/
  
  def _expand(template, args, params)
    raise StandardError.new("expand :for argument evaluates to nil") if params.has_key?(:for) && params[:for].nil?
    context = params[:for]
    @indent = params[:indent] || @indent
    # if this is the first call to expand within this container, @output is nil
    noIndentNextLine = params[:noIndentNextLine]
    noIndentNextLine = (@output.to_s.size > 0 && @output.to_s[-1] != "\n"[0]) if noIndentNextLine.nil?
    old_context, @context = @context, context if context
    local_output = nil
    if template =~ LOCAL_TEMPLATE_REGEX
      tplname = $1
      raise StandardError.new("Template not found: #{$1}") unless @templates[tplname]
      old_output, @output = @output, OutputHandler.new(@indent, @parent.indentString)
      @output.noIndentNextLine if noIndentNextLine
      _call_template(tplname, @context, args)
      local_output, @output = @output, old_output
    else
      local_output = @parent.expand(template, *(args.dup << {:for => @context, :indent => @indent, :noIndentNextLine => noIndentNextLine}))
    end
    _direct_concat(local_output)
    @context = old_context if old_context
    local_output
  end
  
  def processAndRaise(e, tpl=nil)
    bt = e.backtrace.dup
    e.backtrace.each_with_index do |t,i|
      if t =~ /\(erb\):(\d+):/
        bt[i] = "#{@filename}:#{$1}"
        bt[i] += ":in '#{tpl}'" if tpl
        break
      end
    end
    raise e, e.to_s, bt
  end

  def _call_template(tpl, context, args)
    found = false
    @templates[tpl].each_pair do |key, value| 
      if context.is_a?(key)
        proc = @templates[tpl][key]
        arity = proc.arity
        arity = 0 if arity == -1	# if no args are given
        raise StandardError.new("Wrong number of arguments calling template #{tpl}: #{args.size} for #{arity} "+
          "(Beware: Hashes as last arguments are taken as options and are ignored)") \
          if arity != args.size
        begin
          @@metamodels = @metamodels
          proc.call(*args) 
        rescue Exception => e
          processAndRaise(e, tpl)
        end
        found = true
      end
    end
    raise StandardError.new("Template class not matching: #{tpl} for #{context.class.name}") unless found
  end
  
  def _direct_concat(s)
    if @output.is_a? OutputHandler
      @output.direct_concat(s)
    else
      @output << s
    end
  end
  
  def _detectNewLinePattern(text)
    tests = 0
    rnOccurances = 0
    text.scan(/(\r?)\n/) do |r|
      tests += 1
      rnOccurances += 1 if r == "\r"
      break if tests >= 10
    end
    if rnOccurances > (tests / 2)
      @newLinePattern = "\r\n"
    else
      @newLinePattern = "\n"
    end
  end
end
  
end
  
end