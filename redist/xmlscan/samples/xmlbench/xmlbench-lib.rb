#
# samples/xmlbench/xmlbench-lib.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlbench-lib.rb,v 1.3 2002/12/29 17:18:57 katsu Exp $
#

class XMLBench

  def name
    self.class.name
  end

  def weight
    0
  end

  def parse(src)
    raise NotImplementedError, "abstract method"
  end

end



class XMLBench

  ParserDir = File.expand_path(File.dirname(__FILE__)) + '/parser'
  @@parsers = []
  @@parser_classes = []
  @@weight_limit = 0

  class << self

    def weight_limit=(n)
      @@weight_limit = n
    end

    private

    def load(name)
      @@parsers.push name
      filename = "#{XMLBench::ParserDir}/#{name}.rb"
      ret = nil
      if File.file? filename then
        loaded = true
        begin
          Kernel.load "#{XMLBench::ParserDir}/#{name}.rb"
        rescue Exception
        loaded = false
        end
        if loaded then
          klasses = []
          ObjectSpace.each_object(Class) { |klass|
            if not equal? klass and klass.ancestors.include? self then
              klasses.push klass
            end
          }
          ret = klasses - @@parser_classes
          @@parser_classes = klasses
          ret.sort! { |a,b| a.name <=> b.name }
        end
      end
      ret
    end

    public

    def setup(*args)
      ret = []
      args.each { |name|
        next if @@parsers.include? name
        STDERR.print "checking for #{name} ..." if $VERBOSE
        klasses = load(name)
        unless klasses then
          STDERR.print " no" if $VERBOSE
        else
          parsers = []
          klasses.each { |klass|
            begin
              obj = klass.new
            rescue Exception
              obj = nil
            end
            parsers.push obj if obj
          }
          if $VERBOSE then
            if parsers.size < klasses.size then
              STDERR.print " ok (#{klasses.size - parsers.size} failed)"
            else
              STDERR.print " ok"
            end
          end
          parsers.reject! { |i| i.weight > @@weight_limit }
          ret.concat parsers
        end
        STDERR.print "\n" if $VERBOSE
      }
      ret
    end

    def setup_all
      files = Dir.entries(XMLBench::ParserDir)
      files.reject! { |i| /\.rb\z/ !~ i }
      files.collect! { |i| i[0..-4] }
      xmlscan = files.select { |i| /\Axmlscan/ =~ i }
      files = files.reject { |i| /\Axmlscan/ =~ i }
      xmlscan.sort!
      files.sort!
      setup(*xmlscan.concat(files))
    end

  end

end
