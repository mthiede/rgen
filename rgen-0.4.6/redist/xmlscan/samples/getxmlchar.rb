#!/usr/bin/ruby
#
# getxmlchar.rb - get XML-valid characters from XML 1.0 Specification.
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: getxmlchar.rb,v 1.2 2002/09/27 02:33:40 katsu Exp $
#

require 'xmlscan/parser'


class String

  def decamel
    gsub(/[a-z](?=[A-Z])|[A-Z](?=([A-Z][a-z])|((?=[a-z])))/){ |s|
      ($1 ? s : s.downcase) + ($2 || '_')
    }
  end

end



class ProductionGetter

  include XMLScan::Visitor

  def initialize(targets)
    @targets = targets
    @parser = XMLScan::XMLParser.new(self)
    @elem = nil
    @content = nil
    @current = nil
    @production = {}
  end

  attr_reader :production

  def parse(src)
    @parser.parse src
  end

  def on_stag(name)
    if name == 'lhs' or name == 'rhs' then
      @elem = name
      @content = ''
    end
  end

  def on_chardata(str)
    if @content then
      @content << str
    end
  end

  def on_cdata(str)
    on_chardata str
  end

  def on_etag(name)
    case name
    when 'lhs' then
      if @targets.include? @content then
        if $VERBOSE then
          STDERR.puts "`#{@content}' is found at line #{@parser.lineno}."
        end
        @current = @content
      end
    when 'rhs' then
      if @current then
        @production[@current] = @content
      end
      @current = nil
    end
    @elem = nil
    @content = nil
  end

end





def ARGF.path
  filename
end

Productions = %w(Char BaseChar Ideographic CombiningChar Digit Extender)

p = ProductionGetter.new(Productions)
p.parse ARGF

#   0x0041..0x005A,  0x0061..0x007A,  0x00C0..0x00D6,  0x00D8..0x00F6,
# |-^--+----|----+---^|----+----|----+^---|----+----|--^-+----|----+----|
# 0 2                19               36               53

Productions.each { |name|
  prod = p.production[name]
  unless prod then
    print "#{name} = []    # not found\n"
  else
    ranges = []
    prod.scan(/\#x([0-9A-Fa-f]+)(?:-\#x([0-9A-Fa-f]+))?/) { |rstart,rend|
      rend = rend || rstart
      ranges.push Range.new(rstart.hex, rend.hex)
    }
    ranges.sort! { |a,b| a.begin <=> b.begin }
    print "#{name.decamel} = ["
    column = 0
    ranges.each { |i|
      column += 1
      print "\n  " if column == 1
      s = sprintf("0x%04X..0x%04X,", i.begin, i.end)
      s = s.ljust(17) if column < 4
      print s
      column = 0 if column >= 4
    }
    print "\n]\n"
  end
}
