#
# tests/xmlchar.rb
#
#   Copyright (C) Ueno Katsuhiro 2002
#
# $Id: testxmlchar.rb,v 1.4 2005/05/22 07:07:12 nahi Exp $
#

require 'test/unit'
require 'deftestcase'
require 'xmlscan/xmlchar'
require 'visitor'


class TestXMLChar < Test::Unit::TestCase

  include XMLScan::XMLChar

  def test_valid_char_p
    assert_equal true, valid_char?(9)
    assert_equal true, valid_char?(10)
    assert_equal true, valid_char?(13)
    assert_equal true, valid_char?(32)
    assert_equal false, valid_char?(8)
    assert_equal true, valid_char?(0xfffd)
    assert_equal false, valid_char?(0xfffe)
    assert_equal false, valid_char?(0xffff)
    assert_equal false, valid_char?(0x200000)
  end


  # \xE3\x81\xBB = ho
  # \xE3\x81\x92 = ge
  # \xE3\x81\xB5 = fu
  # \xE3\x81\x8C = ga

  Hoge = "\xE3\x81\xBB\xE3\x81\x92"
  Fuga = "\xE3\x81\xB5\xE3\x81\x8C"

  Testcases = [
    #                   chardata? nmtoken?    name?
    [ 'hogefuga',           true,    true,    true ],
    [ Hoge+Fuga,            true,    true,    true ],
    [ Hoge+' '+Fuga,        true,   false,   false ],
    [ Hoge+"\n"+Fuga,       true,   false,   false ],
    [ Hoge+"\r"+Fuga,       true,   false,   false ],
    [ Hoge+"\t"+Fuga,       true,   false,   false ],
    [ Hoge+"\f"+Fuga,      false,   false,   false ],
    [ Hoge+'.'+Fuga,        true,    true,    true ],
    [ Hoge+'-'+Fuga,        true,    true,    true ],
    [ Hoge+'_'+Fuga,        true,    true,    true ],
    [ Hoge+':'+Fuga,        true,    true,    true ],
    [ Hoge+'%'+Fuga,        true,   false,   false ],
    [ '.'+Hoge+Fuga,        true,    true,   false ],
    [ '-'+Hoge+Fuga,        true,    true,   false ],
    [ '_'+Hoge+Fuga,        true,    true,    true ],
    [ ':'+Hoge+Fuga,        true,    true,    true ],
    [ '%'+Hoge+Fuga,        true,   false,   false ],
    [ Hoge+"\xfe"+Fuga,    false,   false,   false ],
    [ Hoge+"\xff"+Fuga,    false,   false,   false ],
    [ [0xffff].pack('U'),  false,   false,   false ],
  ]


  def test_valid_chardata_p
    Testcases.each { |str,expect,|
      assert_equal expect, valid_chardata?(str), str.inspect
    }
  end

  def test_valid_nmtoken_p
    Testcases.each { |str,dummy,expect,|
      assert_equal expect, valid_nmtoken?(str), str.inspect
    }
  end

  def test_valid_name_p
    Testcases.each { |str,dummy,dummy,expect,|
      assert_equal expect, valid_name?(str), str.inspect
    }
  end

end



class TestXMLScannerStrict < Test::Unit::TestCase

  include DefTestCase

  Visitor = RecordingVisitor.new_class(XMLScan::Visitor)


  private

  def setup
    @origkcode = $KCODE
    $KCODE = 'U'
    @v = Visitor.new
    @s = XMLScan::XMLScanner.new(@v, :strict_char)
  end

  def teardown
    $KCODE = @origkcode
  end

  def parse(src)
    @s.parse src
    @v.result
  end


  public

  Hoge = TestXMLChar::Hoge
  Fuga = TestXMLChar::Fuga


  deftestcase 'document', <<-'TESTCASEEND'

  "<:.#{Hoge}>hoge</:.#{Hoge}>"
  [ :on_stag, ":.#{Hoge}" ]
  [ :on_stag_end, ":.#{Hoge}" ]
  [ :on_chardata, "hoge" ]
  [ :on_etag, ":.#{Hoge}" ]

  "<.:#{Hoge}>hoge</.:#{Hoge}>"
  [ :parse_error, "`.:#{Hoge}' is not valid for XML name"]
  [ :on_stag, ".:#{Hoge}" ]
  [ :on_stag_end, ".:#{Hoge}" ]
  [ :on_chardata, "hoge" ]
  [ :parse_error, "`.:#{Hoge}' is not valid for XML name"]
  [ :on_etag, ".:#{Hoge}" ]

  TESTCASEEND

end





load "#{File.dirname($0)}/runtest.rb" if __FILE__ == $0
