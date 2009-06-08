#
# tests/xmlchar.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: testencoding.rb,v 1.5 2003/02/28 12:31:07 katsu Exp $
#

require 'test/unit'
require 'xmlscan/encoding'


class TestEncoding < Test::Unit::TestCase

  NoMethodError = NameError unless defined? NoMethodError

  class MyEncodingClass < XMLScan::EncodingClass
    class << self
      public :new
    end
  end

  EncodingError = XMLScan::EncodingError

  class FugaConverter < XMLScan::Converter
    def initialize
      @hoge = 'FUGA'
    end
    def convert(s)
      ret = "#{@hoge}:#{s}:BUYO"
      @hoge = ''
      ret
    end
    def finish
      "FOOBAR"
    end
  end


  NONE = //n.kcode
  EUC  = //e.kcode
  SJIS = //s.kcode
  UTF8 = //u.kcode


  def setup
    @e = MyEncodingClass.new
    @e.add_converter('hoge', 'fuga', 10) { |s| "HOGE:#{s}:FUGA" }
    @e.add_converter('fuga', 'buyo', 10, FugaConverter)
    @e.set_kcode 'hoge', 'E'
    @e.set_kcode 'fuga', 'S'
  end


  def test_s_new
    assert_raises(NoMethodError) { XMLScan::EncodingClass.new }
  end

  def test_s_instance
    assert_kind_of XMLScan::EncodingClass, XMLScan::Encoding
  end

  def test_preset_kcode
    assert_equal UTF8, XMLScan::Encoding.kcode('utf-8')
    assert_equal nil, XMLScan::Encoding.kcode('utf-16')
    assert_equal nil, XMLScan::Encoding.kcode('iso-10646-ucs-2')
    assert_equal nil, XMLScan::Encoding.kcode('iso-10646-ucs-4')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-1')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-2')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-3')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-4')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-5')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-6')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-7')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-8')
    assert_equal NONE, XMLScan::Encoding.kcode('iso-8859-9')
    assert_equal nil, XMLScan::Encoding.kcode('iso-2022-jp')
    assert_equal SJIS, XMLScan::Encoding.kcode('shift_jis')
    assert_equal SJIS, XMLScan::Encoding.kcode('windows-31J')
    assert_equal EUC, XMLScan::Encoding.kcode('euc-jp')
    assert_equal EUC, XMLScan::Encoding.kcode('euc-kr')
  end


  def test_alias
    assert_nil @e.alias('foo', 'hoge')
    assert_equal EUC, @e.kcode('foo')
    c = nil
    assert_nothing_raised { c = @e.converter('foo', 'fuga') }
    assert_equal "HOGE:foo:FUGA", c.convert("foo")
  end

  def test_alias_share
    assert_nil @e.alias('foo', 'hoge')
    @e.add_converter('hoge', 'buyo', 10) { |s| "HOGE:#{s}:BUYO" }
    c = nil
    assert_nothing_raised { c = @e.converter('foo', 'buyo') }
    assert_equal "HOGE:foo:BUYO", c.convert("foo")
  end

  def test_alias_chain
    assert_nil @e.alias('foo', 'hoge')
    assert_nil @e.alias('bar', 'foo')
    assert_equal EUC, @e.kcode('bar')
    c = nil
    assert_nothing_raised { c = @e.converter('bar', 'fuga') }
    assert_equal "HOGE:foo:FUGA", c.convert("foo")
  end

  def test_alias_caseinsensitive
    assert_nil @e.alias('FOO', 'hoge')
    assert_equal EUC, @e.kcode('foo')
    c = nil
    assert_nothing_raised { c = @e.converter('foo', 'fuga') }
    assert_equal "HOGE:foo:FUGA", c.convert("foo")
  end

  def test_alias_doubled
    assert_nil @e.alias('foo', 'hoge')
    assert_raises(EncodingError) { @e.alias('foo', 'fuga') }
  end

  def test_alias_doubled_2
    assert_raises(EncodingError) { @e.alias('fuga', 'hoge') }
  end

  def test_alias_doubled_3
    assert_raises(EncodingError) { @e.alias('hoge', 'hoge') }
  end

  def test_alias_undeclared
    assert_raises(EncodingError) { @e.alias('foo', 'bar') }
  end


  def test_kcode
    assert_equal EUC, @e.kcode('hoge')
    assert_equal SJIS, @e.kcode('fuga')
    assert_equal NONE, @e.kcode('buyo')
  end

  def test_kcode_undeclared
    assert_equal NONE, @e.kcode('foo')
  end

  def test_kcode_caseinsensitive
    assert_equal EUC, @e.kcode('HOGE')
    assert_equal SJIS, @e.kcode('FUGA')
    assert_equal NONE, @e.kcode('BUYO')
  end


  def test_set_kcode_e
    assert_equal NONE, @e.kcode('buyo')
    assert_equal EUC, @e.set_kcode('buyo', 'e')
    assert_equal EUC, @e.kcode('buyo')
  end

  def test_set_kcode_u
    assert_equal NONE, @e.kcode('buyo')
    assert_equal UTF8, @e.set_kcode('buyo', 'u')
    assert_equal UTF8, @e.kcode('buyo')
  end

  def test_set_kcode_s
    assert_equal NONE, @e.kcode('buyo')
    assert_equal SJIS, @e.set_kcode('buyo', 's')
    assert_equal SJIS, @e.kcode('buyo')
  end

  def test_set_kcode_n
    assert_equal NONE, @e.kcode('buyo')
    assert_equal NONE, @e.set_kcode('buyo', 'n')
    assert_equal NONE, @e.kcode('buyo')
  end

  def test_set_kcode_emp
    assert_equal NONE, @e.kcode('buyo')
    assert_equal nil, @e.set_kcode('buyo', '')
    assert_equal nil, @e.kcode('buyo')
  end

  def test_set_kcode_nil
    assert_equal NONE, @e.kcode('buyo')
    assert_equal nil, @e.set_kcode('buyo', nil)
    assert_equal nil, @e.kcode('buyo')
  end

  def test_set_kcode_reset
    assert_nothing_raised { @e.set_kcode('hoge', 'e') }
    assert_nothing_raised { @e.set_kcode('fuga', 's') }
  end

  def test_set_kcode_conflict
    assert_raises(EncodingError) { @e.set_kcode('hoge', 'u') }
    assert_raises(EncodingError) { @e.set_kcode('fuga', 'u') }
  end

  def test_set_kcode_conflict_2
    assert_equal NONE, @e.kcode('buyo')
    assert_nothing_raised { @e.set_kcode 'buyo', 'e' }
    assert_equal EUC, @e.kcode('buyo')
    assert_raises(EncodingError) { @e.set_kcode('buyo', 'n') }
  end

  def test_set_kcode_conflict_nil
    assert_equal NONE, @e.kcode('buyo')
    assert_nothing_raised { @e.set_kcode 'buyo', 'n' }
    assert_equal NONE, @e.kcode('buyo')
    assert_raises(EncodingError) { @e.set_kcode('buyo', 'e') }
  end

  def test_set_kcode_caseinsensitive
    @e.set_kcode 'Buyo', 'E'
    assert_equal EUC, @e.kcode('buyo')
    assert_raises(EncodingError) { @e.set_kcode('BUYO', 's') }
  end


  def test_converter
    c = @e.converter('hoge', 'fuga')
    assert_kind_of XMLScan::SimpleConverter, c
    assert_equal "HOGE:foo:FUGA", c.convert('foo')
    assert_equal '', c.finish
    c = @e.converter('fuga', 'buyo')
    assert_kind_of FugaConverter, c
    assert_equal "FUGA:foo:BUYO", c.convert('foo')
    assert_equal ":bar:BUYO", c.convert('bar')
    assert_equal 'FOOBAR', c.finish
  end

  def test_converter_same
    assert_nil @e.converter('hoge', 'hoge')
    assert_nil @e.converter('fuga', 'fuga')
  end

  def test_converter_unregistered
    assert_raises(EncodingError) { @e.converter('hoge', 'buyo') }
    assert_raises(EncodingError) { @e.converter('buyo', 'hoge') }
    assert_raises(EncodingError) { @e.converter('fuga', 'hoge') }
    assert_raises(EncodingError) { @e.converter('foo', 'bar') }
  end

  def test_converter_caseinsensitive
    assert_nothing_raised { @e.converter('HOGE', 'fuGA') }
    assert_raises(EncodingError) { @e.converter('HogE', 'BuYo') }
  end


  def test_add_converter
    assert_nil @e.add_converter('buyo', 'foo', 0) { |s| "BUYO:#{s}:FOO" }
    c = nil
    assert_nothing_raised { c = @e.converter('buyo', 'foo') }
    assert_equal "BUYO:foo:FOO", c.convert("foo")
  end

  def test_add_converter_proc
    assert_nil @e.add_converter('hoge', 'buyo', 20) { |s| "HOGE:#{s}:BUYO" }
    c = @e.converter('hoge', 'buyo')
    assert_kind_of XMLScan::SimpleConverter, c
    assert_equal "HOGE:foo:BUYO", c.convert('foo')
  end

  def test_add_converter_proc_2
    assert_nil @e.add_converter('hoge', 'buyo', 20, proc{|s| "HOGE:#{s}:BUYO"})
    c = @e.converter('hoge', 'buyo')
    assert_kind_of XMLScan::SimpleConverter, c
    assert_equal "HOGE:foo:BUYO", c.convert('foo')
  end

  def test_add_converter_klass
    assert_nil @e.add_converter('hoge', 'buyo', 20, FugaConverter)
    c = @e.converter('hoge', 'buyo')
    assert_kind_of FugaConverter, c
    assert_equal "FUGA:foo:BUYO", c.convert('foo')
  end

  def test_add_converter_argerror
    assert_raises(ArgumentError) { @e.add_converter('hoge', 'buyo', 20) }
    assert_raises(ArgumentError) {
      @e.add_converter('hoge', 'buyo', 20, FugaConverter) { }
    }
  end

  def test_add_converter_invalid
    assert_nil @e.add_converter('hoge', 'buyo', 20, Object.new)
    assert_raises(NoMethodError) { @e.converter('hoge', 'buyo') }
  end

  def test_add_converter_heavier
    assert_nil @e.add_converter('hoge', 'fuga', 20) { |s| "hOGE:#{s}:fUGA" }
    c = @e.converter('hoge', 'fuga')
    assert_equal "HOGE:foo:FUGA", c.convert("foo")
  end

  def test_add_converter_lighter
    assert_nil @e.add_converter('hoge', 'fuga', 0) { |s| "hoge:#{s}:fuga" }
    c = @e.converter('hoge', 'fuga')
    assert_equal "hoge:foo:fuga", c.convert("foo")
  end

  def test_add_converter_as_heavy_as
    assert_nil @e.add_converter('hoge', 'fuga', 10) { |s| "hOGe:#{s}:fUGa" }
    c = @e.converter('hoge', 'fuga')
    assert_equal "hOGe:foo:fUGa", c.convert("foo")
  end

  def test_add_converter_same_encoding
    assert_raises(EncodingError) { @e.add_converter('hoge', 'hoge', 10){} }
  end

  def test_add_converter_same_encoding_alias
    @e.alias 'foo', 'hoge'
    assert_raises(EncodingError) { @e.add_converter('hoge', 'foo', 10){} }
    assert_raises(EncodingError) { @e.add_converter('foo', 'hoge', 10){} }
  end

  def test_add_converter_caseinsensitive
    assert_nil @e.add_converter('HOGE', 'BUYO', 10) { |s| "HOGE:#{s}:BUYO" }
    c = nil
    assert_nothing_raised { c = @e.converter('hoge', 'buyo') }
    assert_equal 'HOGE:foo:BUYO', c.convert('foo')
  end


  def test_converter3
    c1, kcode, c2 = @e.converter3('hoge', 'buyo')
    assert_equal "HOGE:foo:FUGA", c1.convert('foo')
    assert_equal SJIS, kcode
    assert_equal "FUGA:bar:BUYO", c2.convert('bar')
  end

  def test_converter3_2
    c1, kcode, c2 = @e.converter3('hoge', nil)
    assert_equal nil, c1
    assert_equal EUC, kcode
    assert_equal nil, c2
    c1, kcode, c2 = @e.converter3('hoge')
    assert_equal nil, c1
    assert_equal EUC, kcode
    assert_equal nil, c2
  end

  def test_converter3_3
    c1, kcode, c2 = @e.converter3('hoge', 'fuga')
    if c1 then
      assert_equal "HOGE:foo:FUGA", c1.convert('foo')
      assert_equal SJIS, kcode
      assert_equal nil, c2
    else
      assert_equal nil, c1
      assert_equal EUC, kcode
      assert_equal "HOGE:foo:FUGA", c2.convert('foo')
    end
  end

  def test_converter3_4
    c1, kcode, c2 = @e.converter3('fuga', 'buyo')
    assert_equal nil, c1
    assert_equal SJIS, kcode
    assert_equal "FUGA:foo:BUYO", c2.convert('foo')
  end

  def test_converter3_5
    c1, kcode, c2 = @e.converter3('buyo')
    assert_equal nil, c1
    assert_equal NONE, kcode
    assert_equal nil, c2
  end

  def test_converter3_6
    assert_raises(EncodingError) { @e.converter3('buyo', 'hoge') }
  end

  def test_conveter3_select
    @e.add_converter('hoge', 'foo', 8) { |s| "HOGE:#{s}:FOO" }
    @e.add_converter('foo', 'buyo', 10) { |s| "FOO:#{s}:BUYO" }
    @e.set_kcode 'foo', 'U'
    c1, kcode, c2 = @e.converter3('hoge', 'buyo')
    assert_equal "HOGE:foo:FOO", c1.convert('foo')
    assert_equal UTF8, kcode
    assert_equal "FOO:bar:BUYO", c2.convert('bar')
  end

  def test_conveter3_select_2
    @e.add_converter('hoge', 'foo', 8) { |s| "HOGE:#{s}:FOO" }
    @e.set_kcode 'foo', 'U'
    c1, kcode, c2 = @e.converter3('hoge', 'buyo')
    assert_equal "HOGE:foo:FUGA", c1.convert('foo')
    assert_equal SJIS, kcode
    assert_equal "FUGA:bar:BUYO", c2.convert('bar')
  end

  def test_conveter3_select_3
    @e.add_converter('hoge', 'foo', 8) { |s| "HOGE:#{s}:FOO" }
    @e.add_converter('foo', 'buyo', 20) { |s| "FOO:#{s}:BUYO" }
    @e.set_kcode 'foo', 'U'
    c1, kcode, c2 = @e.converter3('hoge', 'buyo')
    assert_equal "HOGE:foo:FUGA", c1.convert('foo')
    assert_equal SJIS, kcode
    assert_equal "FUGA:bar:BUYO", c2.convert('bar')
  end

  def test_conveter3_select_4
    @e.add_converter('hoge', 'foo', 20) { |s| "HOGE:#{s}:FOO" }
    @e.add_converter('foo', 'buyo', 8) { |s| "FOO:#{s}:BUYO" }
    @e.set_kcode 'foo', 'U'
    c1, kcode, c2 = @e.converter3('hoge', 'buyo')
    assert_equal "HOGE:foo:FUGA", c1.convert('foo')
    assert_equal SJIS, kcode
    assert_equal "FUGA:bar:BUYO", c2.convert('bar')
  end

  def test_conveter3_select_5
    @e.add_converter('hoge', 'foo', 5) { |s| "HOGE:#{s}:FOO" }
    @e.add_converter('foo', 'buyo', 5) { |s| "FOO:#{s}:BUYO" }
    @e.set_kcode 'foo', nil
    c1, kcode, c2 = @e.converter3('hoge', 'buyo')
    assert_equal "HOGE:foo:FUGA", c1.convert('foo')
    assert_equal SJIS, kcode
    assert_equal "FUGA:bar:BUYO", c2.convert('bar')
  end

  def test_conveter3_select_6
    @e.add_converter('hoge', 'foo', 5) { |s| "HOGE:#{s}:FOO" }
    @e.add_converter('foo', 'buyo', 5) { |s| "FOO:#{s}:BUYO" }
    c1, kcode, c2 = @e.converter3('hoge', 'buyo')
    assert_equal "HOGE:foo:FUGA", c1.convert('foo')
    assert_equal SJIS, kcode
    assert_equal "FUGA:bar:BUYO", c2.convert('bar')
  end

end




load "#{File.dirname($0)}/runtest.rb" if __FILE__ == $0
