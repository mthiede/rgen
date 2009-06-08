#!/usr/bin/ruby
#
# langsplit.rb
#
# $Id: langsplit.rb,v 1.1 2003/01/22 16:41:45 katsu Exp $
#


class TextBlockReader

  def initialize(file)
    @file = file
    @last = nil
  end

  public

  def gets
    lang = nil
    @last = @last || @file.gets
    lang = $1 if /\A\s+([a-z][a-z])\| / =~ @last
    dst = []
    while @last
      if /\A\s*\z/ =~ @last then
        dst.push @last
        dst.push @last while /\A\s*\z/ =~ (@last = @file.gets)
        break
      elsif /\A\s+([a-z][a-z])\|(?: | *$)/ =~ @last then
        break unless $1 == lang
        dst.push $'
      else
        break if lang
        dst.push @last
      end
      @last = @file.gets
    end
    (@last or not dst.empty?) and [ lang, dst ]
  end

end


class LangSplit

  DefaultLanguage = 'ja'

  def initialize(filename, lang)
    lang = nil if lang == DefaultLanguage
    @lang = lang
    @file = File.open(filename)
    @reader = TextBlockReader.new(@file)
    @last = nil
  end

  def close
    @file.close
  end

  def self.open(*args)
    f = new(*args)
    begin
      yield f
    ensure
      f.close
    end
  end

  def gets
    lang, text = @last = @last || @reader.gets
    return nil unless @last
    raise "syntax error" if lang
    indent = text.reject { |i| i.strip.empty? }.
      collect { |i| /\A\s*/.match(i)[0] }.
      min { |a,b| a.size <=> b.size }
    lastspace = []
    texts = {}
    while true
      lastspace.clear
      lastspace.push text.pop while /\A\s*\z/ =~ text.last
      (texts[lang] || texts[lang] = []).concat(text)
      @last = @reader.gets
      lang, text = @last
      break unless @last and lang
      text.each { |i| i[0,0] = indent unless i.strip.empty? }
    end
    (texts[@lang] || texts[nil]).concat(lastspace).join
  end

  def each
    while s = gets
      yield s
    end
  end

end




lang = nil

ARGV.each { |arg|
  if /\A-([a-z][a-z])\z/ =~ arg then
    lang = $1
  else
    LangSplit.open(arg, lang) { |f|
      f.each { |i| print i }
    }
  end
}
