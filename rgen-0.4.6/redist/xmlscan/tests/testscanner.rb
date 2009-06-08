#
# tests/testscanner.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: testscanner.rb,v 1.35 2003/03/17 02:15:43 katsu Exp $
#

require 'test/unit'
require 'deftestcase'
require 'xmlscan/scanner'
require 'visitor'


class TestVisitor < Test::Unit::TestCase

  def test_method_defined
    expect = XMLScan::XMLScanner.private_instance_methods.select { |i|
      i == 'parse_error' or i == 'wellformed_error' or
        i == 'valid_error' or i == 'warning' or /\Aon_/ =~ i
    }.sort
    actual = XMLScan::Visitor.instance_methods.sort
    assert_equal expect, actual
  end

end




class TestXMLScanner < Test::Unit::TestCase

  include DefTestCase

  Visitor = RecordingVisitor.new_class(XMLScan::Visitor)


  private

  def setup
    @v = Visitor.new
    @s = XMLScan::XMLScanner.new(@v)
  end

  def parse(src)
    @s.parse src
    @v.result
  end


  public

  def test_kcode_e
    @s.kcode = 'E'
    assert_equal 'euc', @s.kcode
  end

  def test_kcode_s
    @s.kcode = 'S'
    assert_equal 'sjis', @s.kcode
  end

  def test_kcode_u
    @s.kcode = 'U'
    assert_equal 'utf8', @s.kcode
  end

  def test_kcode_n
    @s.kcode = 'N'
    assert_equal 'none', @s.kcode
  end

  def test_kcode_nil
    @s.kcode = nil
    assert_equal nil, @s.kcode
  end


  def test_lineno_nil
    assert_nil @s.lineno
  end

  def test_lineno_1
    proc{|i|@v.instance_eval{@s=i}}.call(@s)
    def @v.on_chardata(*)
      @l = @s.lineno
    end
    @s.parse "hoge"
    assert_equal 0, @v.instance_eval{@l}
    assert_equal nil, @s.lineno
  end

  def test_lineno_2
    s = "hoge"
    def s.lineno
      123
    end
    proc{|i|@v.instance_eval{@s=i}}.call(@s)
    def @v.on_chardata(*)
      @l = @s.lineno
    end
    @s.parse s
    assert_equal 123, @v.instance_eval{@l}
    assert_equal nil, @s.lineno
  end


  def test_path_nil
    assert_nil @s.path
  end

  def test_path_1
    proc{|i|@v.instance_eval{@s=i}}.call(@s)
    def @v.on_chardata(*)
      @p = @s.path
    end
    @s.parse "hoge"
    assert_equal '-', @v.instance_eval{@p}
    assert_equal nil, @s.path
  end

  def test_path_2
    s = "hoge"
    def s.path
      'fuga'
    end
    proc{|i|@v.instance_eval{@s=i}}.call(@s)
    def @v.on_chardata(*)
      @p = @s.path
    end
    @s.parse s
    assert_equal 'fuga', @v.instance_eval{@p}
    assert_equal nil, @s.path
  end


  deftestcase 'chardata', <<-'TESTCASEEND'

  'hogefuga'
  [ :on_chardata, 'hogefuga' ]

  'hoge>fuga'
  [ :on_chardata, 'hoge' ]
  [ :on_chardata, '>fuga' ]

  '>>hoge>>fuga>>'
  [ :on_chardata, '>' ]
  [ :on_chardata, '>hoge' ]
  [ :on_chardata, '>' ]
  [ :on_chardata, '>fuga' ]
  [ :on_chardata, '>' ]
  [ :on_chardata, '>' ]

  '>hoge>fuga>'
  [ :on_chardata, '>hoge' ]
  [ :on_chardata, '>fuga' ]
  [ :on_chardata, '>' ]

  '>'
  [ :on_chardata, '>' ]

  ''

  'hoge&fuga;hoge'
  [ :on_chardata, 'hoge' ]
  [ :on_entityref, 'fuga' ]
  [ :on_chardata, 'hoge' ]

  '&hoge;fuga&hoge;'
  [ :on_entityref, 'hoge' ]
  [ :on_chardata, 'fuga' ]
  [ :on_entityref, 'hoge' ]

  'hoge&#1234;fuga'
  [ :on_chardata, 'hoge' ]
  [ :on_charref, 1234 ]
  [ :on_chardata, 'fuga' ]

  'hoge&#x1234;fuga'
  [ :on_chardata, 'hoge' ]
  [ :on_charref_hex, 0x1234 ]
  [ :on_chardata, 'fuga' ]

  'hoge&#xasdf;fuga'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "invalid character reference `#xasdf'" ]
  [ :on_chardata, 'fuga' ]

  'hoge&#12ad;fuga'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "invalid character reference `#12ad'" ]
  [ :on_chardata, 'fuga' ]

  'hoge&fuga hoge'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "reference to `fuga' doesn't end with `;'" ]
  [ :on_entityref, 'fuga' ]
  [ :on_chardata, ' hoge' ]

  'hoge&#1234 hoge'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "reference to `#1234' doesn't end with `;'" ]
  [ :on_charref, 1234 ]
  [ :on_chardata, ' hoge' ]

  'hoge&#x1234 hoge'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "reference to `#x1234' doesn't end with `;'" ]
  [ :on_charref_hex, 0x1234 ]
  [ :on_chardata, ' hoge' ]

  'hoge&#fuga hoge'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "reference to `#fuga' doesn't end with `;'" ]
  [ :parse_error, "invalid character reference `#fuga'" ]
  [ :on_chardata, ' hoge' ]

  'hoge&fu ga;hoge'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "reference to `fu' doesn't end with `;'" ]
  [ :on_entityref, 'fu' ]
  [ :on_chardata, ' ga;hoge' ]

  'hoge &#### fuga'
  [ :on_chardata, 'hoge ' ]
  [ :parse_error, "reference to `####' doesn't end with `;'" ]
  [ :parse_error, "invalid character reference `####'" ]
  [ :on_chardata, ' fuga' ]

  'hoge & fuga'
  [ :on_chardata, 'hoge ' ]
  [ :parse_error, "`&' is not used for entity/character references" ]
  [ :on_chardata, '& fuga' ]

  'hoge &; fuga'
  [ :on_chardata, 'hoge ' ]
  [ :parse_error, "`&' is not used for entity/character references" ]
  [ :on_chardata, '&; fuga' ]

  'hoge &! fuga'
  [ :on_chardata, 'hoge ' ]
  [ :parse_error, "`&' is not used for entity/character references" ]
  [ :on_chardata, '&! fuga' ]

  'hoge&fu>ga;hoge'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "reference to `fu' doesn't end with `;'" ]
  [ :on_entityref, 'fu' ]
  [ :on_chardata, '>ga;hoge' ]

  'hoge&#12>34;hoge'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "reference to `#12' doesn't end with `;'" ]
  [ :on_charref, 12 ]
  [ :on_chardata, '>34;hoge' ]

  TESTCASEEND



  deftestcase 'comment', <<-'TESTCASEEND'

  '<!-- hogefuga -->'
  [ :on_comment, ' hogefuga ' ]

  '<!-- hoge<a>fuga -->'
  [ :on_comment, ' hoge<a>fuga ' ]

  '<!-- hoge<<<>>><<<a>>>fuga -->'
  [ :on_comment, ' hoge<<<>>><<<a>>>fuga ' ]

  '<!-- hoge-fuga -->'
  [ :on_comment, ' hoge-fuga ' ]

  '<!-- hogefuga'
  [ :parse_error, 'unterminated comment meets EOF' ]
  [ :on_comment, ' hogefuga' ]

  '<!-- hoge-fuga --  >'
  [ :parse_error, "comment includes `--'" ]
  [ :parse_error, 'unterminated comment meets EOF' ]
  [ :on_comment, ' hoge-fuga --  >' ]

  '<!-- hoge--fuga -- >'
  [ :parse_error, "comment includes `--'" ]
  [ :parse_error, "comment includes `--'" ]
  [ :parse_error, 'unterminated comment meets EOF' ]
  [ :on_comment, ' hoge--fuga -- >' ]

  '<!-- hoge--fuga -->'
  [ :parse_error, "comment includes `--'" ]
  [ :on_comment, ' hoge--fuga ' ]

  '<!-- hoge--<a>fuga -->'
  [ :parse_error, "comment includes `--'" ]
  [ :on_comment, ' hoge--<a>fuga ' ]

  '<!-- hoge<--a>fuga -->'
  [ :parse_error, "comment includes `--'" ]
  [ :on_comment, ' hoge<--a>fuga ' ]

  '<!-- hoge<a>--fuga -->'
  [ :parse_error, "comment includes `--'" ]
  [ :on_comment, ' hoge<a>--fuga ' ]

  '<!-- hoge--fuga'
  [ :parse_error, "comment includes `--'" ]
  [ :parse_error, 'unterminated comment meets EOF' ]
  [ :on_comment, ' hoge--fuga' ]

  '<!--- hogefuga --->'
  [ :parse_error, "comment ending in `--->' is not allowed" ]
  [ :on_comment, '- hogefuga -' ]

  '<!-------->'
  [ :parse_error, "comment includes `--'" ]
  [ :parse_error, "comment includes `--'" ]
  [ :on_comment, '----' ]

  '<!------->'
  [ :parse_error, "comment includes `--'" ]
  [ :parse_error, "comment ending in `--->' is not allowed" ]
  [ :on_comment, '---' ]

  '<!------>'
  [ :parse_error, "comment includes `--'" ]
  [ :on_comment, '--' ]

  '<!----->'
  [ :parse_error, "comment ending in `--->' is not allowed" ]
  [ :on_comment, '-' ]

  '<!---->'
  [ :on_comment, '' ]

  '<!--->'
  [ :parse_error, 'unterminated comment meets EOF' ]
  [ :on_comment, '->' ]

  '<!-->'
  [ :parse_error, 'unterminated comment meets EOF' ]
  [ :on_comment, '>' ]

  '<!--hoge-->fuga'
  [ :on_comment, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<!--hoge-->>'
  [ :on_comment, 'hoge' ]
  [ :on_chardata, '>' ]

  '<!--hoge-fuga--->hoge'
  [ :parse_error, "comment ending in `--->' is not allowed" ]
  [ :on_comment, 'hoge-fuga-' ]
  [ :on_chardata, 'hoge' ]

  '<!--hoge--fuga-->hoge'
  [ :parse_error, "comment includes `--'" ]
  [ :on_comment, 'hoge--fuga' ]
  [ :on_chardata, 'hoge' ]

  TESTCASEEND



  deftestcase 'pi', <<-'TESTCASEEND'

  '<?hoge fuga?>'
  [ :on_pi, 'hoge', 'fuga' ]

  '<?hoge  ?>'
  [ :on_pi, 'hoge', '' ]

  "<?hoge\r?>"
  [ :on_pi, 'hoge', '' ]

  "<?hoge\f?>"
  [ :on_pi, "hoge\f", '' ]

  "<?hoge\rfuga?>"
  [ :on_pi, 'hoge', 'fuga' ]

  "<?hoge\ffuga?>"
  [ :on_pi, "hoge\ffuga", '' ]

  "<?hoge\f fuga?>"
  [ :on_pi, "hoge\f", 'fuga' ]

  "<?hoge \ffuga?>"
  [ :on_pi, 'hoge', "\ffuga" ]

  '<?hoge?>'
  [ :on_pi, 'hoge', '' ]

  '<?hoge <<>><<<>><<a>>    ?>'
  [ :on_pi, 'hoge', '<<>><<<>><<a>>    ' ]

  '<?hoge<?>'
  [ :parse_error, "parse error at `<?'" ]
  [ :on_chardata, '<?hoge' ]
  [ :parse_error, "parse error at `<?'" ]
  [ :on_chardata, '<?>' ]

  '<?hoge>'
  [ :parse_error, "parse error at `<?'" ]
  [ :on_chardata, '<?hoge>' ]

  '<? ?>'
  [ :parse_error, "parse error at `<?'" ]
  [ :on_chardata, '<? ?>' ]

  '<??>'
  [ :parse_error, "parse error at `<?'" ]
  [ :on_chardata, '<??>' ]

  '<??'
  [ :parse_error, "parse error at `<?'" ]
  [ :on_chardata, '<??' ]

  '<?'
  [ :parse_error, "parse error at `<?'" ]
  [ :on_chardata, '<?' ]

  '<?hoge?>fuga'
  [ :on_pi, 'hoge', '' ]
  [ :on_chardata, 'fuga' ]

  '<?hoge?>>'
  [ :on_pi, 'hoge', '' ]
  [ :on_chardata, '>' ]

  TESTCASEEND



  deftestcase 'cdata', <<-'TESTCASEEND'

  '<![CDATA[hogefuga]]>'
  [ :on_cdata, 'hogefuga' ]

  '<![CDATA[  ]]>'
  [ :on_cdata, '  ' ]

  '<![CDATA[]]>'
  [ :on_cdata, '' ]

  '<![CDATA[<<<>>><<<>>><<<a>>>]]>'
  [ :on_cdata, '<<<>>><<<>>><<<a>>>' ]

  '<![CDATA[< > < > <a>]]>'
  [ :on_cdata, '< > < > <a>' ]

  '<![CDATA[]]'
  [ :parse_error, "unterminated CDATA section meets EOF" ]
  [ :on_cdata, ']]' ]

  '<![CDATA[]>'
  [ :parse_error, "unterminated CDATA section meets EOF" ]
  [ :on_cdata, ']>' ]

  '<![CDATA[>'
  [ :parse_error, "unterminated CDATA section meets EOF" ]
  [ :on_cdata, '>' ]

  '<![CDATA['
  [ :parse_error, "unterminated CDATA section meets EOF" ]
  [ :on_cdata, '' ]

  '<![CDATA[hoge]]>fuga'
  [ :on_cdata, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<![CDATA[hoge]]>>'
  [ :on_cdata, 'hoge' ]
  [ :on_chardata, '>' ]

  TESTCASEEND



  deftestcase 'etag', <<-'TESTCASEEND'

  '</hoge>'
  [ :on_etag, 'hoge' ]

  '</hoge   >'
  [ :on_etag, 'hoge' ]

  "</hoge\r>"
  [ :on_etag, 'hoge' ]

  "</hoge\f>"
  [ :on_etag, "hoge\f" ]

  '</ hoge>'
  [ :parse_error, "parse error at `</'" ]
  [ :on_chardata, '</ hoge>' ]

  '</hoge fuga>'
  [ :parse_error, "illegal whitespace is found within end tag `hoge'" ]
  [ :on_etag, 'hoge' ]

  '</hoge'
  [ :parse_error, "unclosed end tag `hoge' meets EOF" ]
  [ :on_etag, 'hoge' ]

  '</hoge</fuga>'
  [ :parse_error, "unclosed end tag `hoge' meets another tag" ]
  [ :on_etag, 'hoge' ]
  [ :on_etag, 'fuga' ]

  '</>'
  [ :parse_error, "parse error at `</'" ]
  [ :on_chardata, '</>' ]

  '</</'
  [ :parse_error, "parse error at `</'" ]
  [ :on_chardata, '</' ]
  [ :parse_error, "parse error at `</'" ]
  [ :on_chardata, '</' ]

  '</'
  [ :parse_error, "parse error at `</'" ]
  [ :on_chardata, '</' ]

  '</hoge>fuga'
  [ :on_etag, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '</hoge>>'
  [ :on_etag, 'hoge' ]
  [ :on_chardata, '>' ]

  '</hoge fuga>hoge'
  [ :parse_error, "illegal whitespace is found within end tag `hoge'" ]
  [ :on_etag, 'hoge' ]
  [ :on_chardata, 'hoge' ]

  '</hoge</fuga>hoge'
  [ :parse_error, "unclosed end tag `hoge' meets another tag" ]
  [ :on_etag, 'hoge' ]
  [ :on_etag, 'fuga' ]
  [ :on_chardata, 'hoge' ]

  '</hoge</fuga>>'
  [ :parse_error, "unclosed end tag `hoge' meets another tag" ]
  [ :on_etag, 'hoge' ]
  [ :on_etag, 'fuga' ]
  [ :on_chardata, '>' ]

  '</>hoge'
  [ :parse_error, "parse error at `</'" ]
  [ :on_chardata, '</>' ]
  [ :on_chardata, 'hoge' ]

  TESTCASEEND



  deftestcase 'stag', <<-'TESTCASEEND'

  '<hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge     >'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  "<hoge\r     >"
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  "<hoge\f     >"
  [ :on_stag, "hoge\f" ]
  [ :on_stag_end, "hoge\f" ]

  '<hoge'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "unclosed start tag `hoge' meets EOF" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge<fuga>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "unclosed start tag `hoge' meets another tag" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]

  '<hoge   <fuga>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "unclosed start tag `hoge' meets another tag" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]

  '<  hoge>'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '<  hoge>' ]

  '<hoge/>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<hoge     />'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<hoge/'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "unclosed empty element tag `hoge' meets EOF" ]
  [ :on_stag_end_empty, 'hoge' ]

  '<hoge/<fuga/>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "unclosed empty element tag `hoge' meets another tag" ]
  [ :on_stag_end_empty, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end_empty, 'fuga' ]

  '<hoge  /<fuga>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "unclosed empty element tag `hoge' meets another tag" ]
  [ :on_stag_end_empty, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]

  '<  hoge  />'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '<  hoge  />' ]

  '<hoge/ >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge= >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `='" ]
  [ :on_stag_end, 'hoge' ]

  '<=hoge >'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '<=hoge >' ]

  '< =hoge >'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '< =hoge >' ]

  '<hoge>fuga'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<hoge>>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, '>' ]

  '<hoge/>fuga'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<hoge/>>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]
  [ :on_chardata, '>' ]

  '< hoge>fuga'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '< hoge>' ]
  [ :on_chardata, 'fuga' ]

  '< hoge>>'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '< hoge>' ]
  [ :on_chardata, '>' ]

  '<hoge/ >fuga'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<hoge/ >>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, '>' ]

  '<>'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '<>' ]

  '<'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '<' ]


  TESTCASEEND



  deftestcase 'attribute', <<-'TESTCASEEND'

  '<hoge foo="bar">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  "<hoge foo =  'bar' HOGE = 'FUGA'  >"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_attribute, 'HOGE' ]
  [ :on_attr_value, 'FUGA' ]
  [ :on_attribute_end, 'HOGE' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="bar"/>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty, 'hoge' ]

  "<hoge foo   =   '  bar  '     />"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, '  bar  ' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty, 'hoge' ]

  "<hoge foo\r=\r'bar'/>"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty, 'hoge' ]

  "<hoge foo\f=\f'bar'/>"
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo\f'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `\f'" ]
  [ :parse_error, "parse error at `''" ]
  [ :parse_error, "parse error at `bar'" ]
  [ :parse_error, "parse error at `''" ]
  [ :on_stag_end_empty, 'hoge' ]

  "<hoge\ffoo='bar'/>"
  [ :on_stag, "hoge\ffoo" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `''" ]
  [ :parse_error, "parse error at `bar'" ]
  [ :parse_error, "parse error at `''" ]
  [ :on_stag_end_empty, "hoge\ffoo" ]

  '<hoge foo="bar" / >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="b>a>b>c>ar">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'b' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'a' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'b' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'c' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'ar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="b>>a>>b>>c>>ar" HOGE="FUGA">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'b' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'a' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'b' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'c' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'ar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_attribute, 'HOGE' ]
  [ :on_attr_value, 'FUGA' ]
  [ :on_attribute_end, 'HOGE' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="b<a>b<c>ar">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'b' ]
  [ :wellformed_error, "`<' is found in attribute `foo'" ]
  [ :on_attr_value, '<a' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'b' ]
  [ :wellformed_error, "`<' is found in attribute `foo'" ]
  [ :on_attr_value, '<c' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'ar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="bar"<fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "unclosed start tag `hoge' meets another tag" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]

  '<hoge foo="bar"'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "unclosed start tag `hoge' meets EOF" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo=bar>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `bar'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   =   bar   >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `bar'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   =   bar&fuga;bar   >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `bar&fuga;bar'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   =   bar<fuga   >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `bar'" ]
  [ :parse_error, "unclosed start tag `hoge' meets another tag" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]

  '<hoge foo= >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo'" ]
  [ :parse_error, "parse error at `='" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="bar"HOGE ="FUGA">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "parse error at `HOGE'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `FUGA'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="bar"=fuga >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `fuga'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="bar>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attr_value, '>' ]
  [ :parse_error, "unterminated attribute `foo' meets EOF" ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "unclosed start tag `hoge' meets EOF" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge="fuga">'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `fuga'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge"fuga">'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `fuga'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_stag_end, 'hoge' ]

  "<hoge foo\r\n\r\nbar='fuga'>"
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `foo'" ]
  [ :on_attribute, 'bar' ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'bar' ]
  [ :on_stag_end, 'hoge' ]


  '<hoge foo="hoge&fuga;hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :on_attr_entityref, 'fuga' ]
  [ :on_attr_value, 'hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="&hoge;fuga&hoge;">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_entityref, 'hoge' ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attr_entityref, 'hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#1234;fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :on_attr_charref, 1234 ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#x1234;fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :on_attr_charref_hex, 0x1234 ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#xasdf;fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "invalid character reference `#xasdf'" ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#12ad;fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "invalid character reference `#12ad'" ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&fuga hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "reference to `fuga' doesn't end with `;'" ]
  [ :on_attr_entityref, 'fuga' ]
  [ :on_attr_value, ' hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&fu ga;hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "reference to `fu' doesn't end with `;'" ]
  [ :on_attr_entityref, 'fu' ]
  [ :on_attr_value, ' ga;hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#1234 hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "reference to `#1234' doesn't end with `;'" ]
  [ :on_attr_charref, 1234 ]
  [ :on_attr_value, ' hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#x1234 hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "reference to `#x1234' doesn't end with `;'" ]
  [ :on_attr_charref_hex, 0x1234 ]
  [ :on_attr_value, ' hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#fuga hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "reference to `#fuga' doesn't end with `;'" ]
  [ :parse_error, "invalid character reference `#fuga'" ]
  [ :on_attr_value, ' hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge &#### fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge ' ]
  [ :parse_error, "reference to `####' doesn't end with `;'" ]
  [ :parse_error, "invalid character reference `####'" ]
  [ :on_attr_value, ' fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge & fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge ' ]
  [ :parse_error, "`&' is not used for entity/character references" ]
  [ :on_attr_value, '& fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge &; fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge ' ]
  [ :parse_error, "`&' is not used for entity/character references" ]
  [ :on_attr_value, '&; fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge &! fuga">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge ' ]
  [ :parse_error, "`&' is not used for entity/character references" ]
  [ :on_attr_value, '&! fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&fu>ga;hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "reference to `fu' doesn't end with `;'" ]
  [ :on_attr_entityref, 'fu' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'ga;hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="hoge&#12>34;hoge">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :parse_error, "reference to `#12' doesn't end with `;'" ]
  [ :on_attr_charref, 12 ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, '34;hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  TESTCASEEND



  deftestcase 'bang_tag', <<-'TESTCASEEND'

  '<!hoge>'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '<!hoge>' ]

  '<!hoge fuga>'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '<!hoge fuga>' ]

  '<!hoge'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '<!hoge' ]

  '<!>'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '<!>' ]

  '<!'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '<!' ]

  '<!hoge>fuga'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '<!hoge>' ]
  [ :on_chardata, 'fuga' ]

  '<!hoge>>'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '<!hoge>' ]
  [ :on_chardata, '>' ]

  TESTCASEEND



  deftestcase 'xmldecl', <<-'TESTCASEEND'

  '<?xml version="1.0"?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]

  "<?xml version='1.0'?>"
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]

  '<?xml version  =  "1.0"  ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]

  "<?xml version\f=\f'1.0'  ?>"
  [ :on_xmldecl ]
  [ :parse_error, "parse error at `version'" ]
  [ :parse_error, "parse error at `\f'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `\f'" ]
  [ :parse_error, "parse error at `''" ]
  [ :parse_error, "parse error at `1.0'" ]
  [ :parse_error, "parse error at `''" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  '<?xml version="" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '' ]
  [ :on_xmldecl_end ]

  '<?xml version="1<0" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1<0' ]
  [ :on_xmldecl_end ]

  '<?xml version="1>0" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1>0' ]
  [ :on_xmldecl_end ]

  '<?xml version="1<<>><<a>>0" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1<<>><<a>>0' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0" encoding="euc-jp"?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_encoding, 'euc-jp' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0" standalone="yes" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0" encoding="euc-jp" standalone="yes" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_encoding, 'euc-jp' ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0" encoding="euc-jp"?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_encoding, 'euc-jp' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0" standalone="yes" encoding="euc-jp"?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :parse_error, "encoding declaration must not be here" ]
  [ :on_xmldecl_encoding, 'euc-jp' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0" standalone="yes" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0" version="1.0" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :parse_error, "version declaration must not be here" ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]

  '<?xml encoding="euc-jp" version="1.0" ?>'
  [ :on_xmldecl ]
  [ :parse_error, "encoding declaration must not be here" ]
  [ :on_xmldecl_encoding, 'euc-jp' ]
  [ :parse_error, "version declaration must not be here" ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]

  '<?xml encoding="euc-jp" standalone="yes" ?>'
  [ :on_xmldecl ]
  [ :parse_error, "encoding declaration must not be here" ]
  [ :on_xmldecl_encoding, 'euc-jp' ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :on_xmldecl_end ]

  '<?xml standalone="yes" version="1.0" ?>'
  [ :on_xmldecl ]
  [ :parse_error, "standalone declaration must not be here" ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :parse_error, "version declaration must not be here" ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]

  '<?xml standalone="yes" encoding="euc-jp" ?>'
  [ :on_xmldecl ]
  [ :parse_error, "standalone declaration must not be here" ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :parse_error, "encoding declaration must not be here" ]
  [ :on_xmldecl_encoding, 'euc-jp' ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0"encoding="euc-jp" standalone="yes" ?>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :parse_error, "parse error at `encoding'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `euc-jp'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :on_xmldecl_end ]

  "<?xml hoge='fuga' ?>"
  [ :on_xmldecl ]
  [ :parse_error, "unknown declaration `hoge' in XML declaration" ]
  [ :on_xmldecl_other, 'hoge', 'fuga' ]
  [ :on_xmldecl_end ]

  '<?xml ?>'
  [ :on_xmldecl ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  '<?xml version="1.0">'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :parse_error, "parse error at `>'" ]
  [ :parse_error, "unterminated XML declaration meets EOF" ]
  [ :on_xmldecl_end ]

  '<?xml >'
  [ :on_xmldecl ]
  [ :parse_error, "parse error at `>'" ]
  [ :parse_error, "unterminated XML declaration meets EOF" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  '<?xml '
  [ :on_xmldecl ]
  [ :parse_error, "unterminated XML declaration meets EOF" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  '<?xml >><<a>> b'
  [ :on_xmldecl ]
  [ :parse_error, "parse error at `>'" ]
  [ :parse_error, "parse error at `>'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `a'" ]
  [ :parse_error, "parse error at `>'" ]
  [ :parse_error, "parse error at `>'" ]
  [ :parse_error, "parse error at `b'" ]
  [ :parse_error, "unterminated XML declaration meets EOF" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  '<?xml version= ?>'
  [ :on_xmldecl ]
  [ :parse_error, "parse error at `version'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  '<?xml version=1.0 ?>'
  [ :on_xmldecl ]
  [ :parse_error, "parse error at `version'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `1.0'" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  '<?xml version!="1.0" ?>'
  [ :on_xmldecl ]
  [ :parse_error, "parse error at `version'" ]
  [ :parse_error, "parse error at `!'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `1.0'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  "<?xml version     !=     '1.0' ?>"
  [ :on_xmldecl ]
  [ :parse_error, "parse error at `version'" ]
  [ :parse_error, "parse error at `!'" ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `''" ]
  [ :parse_error, "parse error at `1.0'" ]
  [ :parse_error, "parse error at `''" ]
  [ :parse_error, "no declaration found in XML declaration" ]
  [ :on_xmldecl_end ]

  "<?xml version = '1.0 ?>"
  [ :on_xmldecl ]
  [ :parse_error, "unterminated XML declaration meets EOF" ]
  [ :on_xmldecl_version, '1.0 ?>' ]
  [ :on_xmldecl_end ]

  "<?xml version='1.0' ?>hoge"
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_chardata, 'hoge' ]

  "<?xml version='1.0' ?>>"
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_chardata, '>' ]

  TESTCASEEND



  deftestcase 'doctype', <<-'TESTCASEEND'

  '<!DOCTYPE hoge >'
  [ :on_doctype, 'hoge', nil, nil ]

  '<!DOCTYPE hoge SYSTEM "fuga">'
  [ :on_doctype, 'hoge', nil, 'fuga' ]

  "<!DOCTYPE hoge PUBLIC 'fuga' >"
  [ :on_doctype, 'hoge', 'fuga', nil ]

  "<!DOCTYPE hoge PUBLIC 'fuga' 'muga'>"
  [ :on_doctype, 'hoge', 'fuga', 'muga' ]

  "<!DOCTYPE hoge PUBLIC 'fu<<a>><<>>ga' 'mu<<>><<>><<a>>ga'>"
  [ :on_doctype, 'hoge', 'fu<<a>><<>>ga', 'mu<<>><<>><<a>>ga' ]

  "<!DOCTYPE hoge SYSTEM 'fuga' 'muga' >"
  [ :parse_error, 'too many external ID literals in DOCTYPE' ]
  [ :on_doctype, 'hoge', nil, 'fuga' ]

  "<!DOCTYPE hoge PUBLIC 'fuga' 'muga' 'foo'>"
  [ :parse_error, 'too many external ID literals in DOCTYPE' ]
  [ :on_doctype, 'hoge', 'fuga', 'muga' ]

  "<!DOCTYPE hoge SYSTEM>"
  [ :parse_error, 'too few external ID literals in DOCTYPE' ]
  [ :on_doctype, 'hoge', nil, nil ]

  "<!DOCTYPE hoge PUBLIC>"
  [ :parse_error, 'too few external ID literals in DOCTYPE' ]
  [ :on_doctype, 'hoge', nil, nil ]

  "<!DOCTYPE hoge public 'fuga' >"
  [ :parse_error, "`PUBLIC' or `SYSTEM' should be here" ]
  [ :on_doctype, 'hoge', nil, 'fuga' ]

  '<!DOCTYPE SYSTEM "hoge">'
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `hoge'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_doctype, 'SYSTEM', nil, nil ]

  '<!DOCTYPE "hoge">'
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `hoge'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "no root element is specified in DOCTYPE" ]
  [ :on_doctype, nil, nil, nil ]

  '<!DOCTYPE hoge <<a<<b<<c<<>'
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `a'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `b'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `c'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :parse_error, "parse error at `<'" ]
  [ :on_doctype, 'hoge', nil, nil ]

  '<!DOCTYPE hoge PUBLIC "fuga" "muga"  '
  [ :parse_error, "unterminated DOCTYPE declaration meets EOF" ]
  [ :on_doctype, 'hoge', 'fuga', 'muga' ]

  '<!DOCTYPE hoge SYSTEM "fuga"   '
  [ :parse_error, "unterminated DOCTYPE declaration meets EOF" ]
  [ :on_doctype, 'hoge', nil, 'fuga' ]

  '<!DOCTYPE hoge SYSTEM "fuga>'
  [ :parse_error, "unterminated DOCTYPE declaration meets EOF" ]
  [ :on_doctype, 'hoge', nil, 'fuga>' ]

  '<!DOCTYPE hoge  '
  [ :parse_error, "unterminated DOCTYPE declaration meets EOF" ]
  [ :on_doctype, 'hoge', nil, nil ]

  '<!DOCTYPE       '
  [ :parse_error, "unterminated DOCTYPE declaration meets EOF" ]
  [ :parse_error, "no root element is specified in DOCTYPE" ]
  [ :on_doctype, nil, nil, nil ]

  '<!DOCTYPE hoge []>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  '<!DOCTYPE hoge[]>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  '<!DOCTYPE hoge SYSTEM "fuga"[ ]>'
  [ :on_doctype, 'hoge', nil, 'fuga' ]
  [ :warning, "internal DTD subset is not supported" ]

  "<!DOCTYPE hoge PUBLIC 'fuga' []>"
  [ :on_doctype, 'hoge', 'fuga', nil ]
  [ :warning, "internal DTD subset is not supported" ]

  "<!DOCTYPE hoge PUBLIC 'fuga' 'muga'[]>"
  [ :on_doctype, 'hoge', 'fuga', 'muga' ]
  [ :warning, "internal DTD subset is not supported" ]

  '<!DOCTYPE hoge >fuga'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_chardata, 'fuga' ]

  '<!DOCTYPE hoge >>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_chardata, '>' ]

  "<!DOCTYPE hoge PUBLIC 'fuga' 'muga' 'foo'>fuga"
  [ :parse_error, 'too many external ID literals in DOCTYPE' ]
  [ :on_doctype, 'hoge', 'fuga', 'muga' ]
  [ :on_chardata, 'fuga' ]

  '<!DOCTYPE "hoge">fuga'
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "parse error at `hoge'" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :parse_error, "no root element is specified in DOCTYPE" ]
  [ :on_doctype, nil, nil, nil ]
  [ :on_chardata, 'fuga' ]

  "<!DOCTYPE hoge\fSYSTEM\f'fuga'>fuga"
  [ :parse_error, "parse error at `''" ]
  [ :parse_error, "parse error at `fuga'" ]
  [ :parse_error, "parse error at `''" ]
  [ :on_doctype, "hoge\fSYSTEM\f", nil, nil ]
  [ :on_chardata, 'fuga' ]

  TESTCASEEND



  deftestcase 'internal_dtd', <<-'TESTCASEEND'

  '<!DOCTYPE hoge[ <!ENTITY fuga "hoge"> ]>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  "<!DOCTYPE hoge[ <!-- ]> --> ]>"
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  "<!DOCTYPE hoge[ <!-- ]> -> ]>"
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]
  [ :parse_error, "unterminated internal DTD subset meets EOF" ]

  "<!DOCTYPE hoge[ <? ]> ?> ]>"
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  "<!DOCTYPE hoge[ <? ]> > ]>"
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]
  [ :parse_error, "unterminated internal DTD subset meets EOF" ]

  '<!DOCTYPE hoge[ <fugaufgaufugaufguafugaf>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]
  [ :parse_error, "unterminated internal DTD subset meets EOF" ]

  "<!DOCTYPE hoge[ <!ENTITY fuga ']>' >>><<>><<a>> ]>"
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  "<!DOCTYPE hoge[ <!ENTITY fuga ']>' \">>><<>><<a>>\" ]>"
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  '<!DOCTYPE hoge[ \"<!-- a \" --> ]>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  '<!DOCTYPE hoge[ "<!? a " ?> ]>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]

  '<!DOCTYPE hoge[ <!ENTITY hoge "fuga" -- ]> -- > ]>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]
  [ :on_chardata, ' -- ' ]
  [ :on_chardata, '> ]' ]
  [ :on_chardata, '>' ]

  '<!DOCTYPE hoge[ fuga ]>hoge'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]
  [ :on_chardata, 'hoge' ]

  '<!DOCTYPE hoge[ fuga ]>>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :warning, "internal DTD subset is not supported" ]
  [ :on_chardata, '>' ]

  TESTCASEEND



  deftestcase 'prolog', <<-'TESTCASEEND'

  '<?xml version="1.0"?><!DOCTYPE hoge><hoge>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<?xml version="1.0"?><hoge><!DOCTYPE hoge>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, "<!DOCTYPE hoge>" ]

  '<!DOCTYPE hoge><hoge><?xml version="1.0"?>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_pi, 'xml', 'version="1.0"' ]

  '<!DOCTYPE hoge><?xml version="1.0"?><hoge>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_pi, 'xml', 'version="1.0"' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<?xml version="1.0"?>  <!DOCTYPE hoge>  <hoge>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_prolog_space, '  ' ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_prolog_space, '  ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '  <?xml version="1.0"?>  <!DOCTYPE hoge>  <hoge>'
  [ :on_prolog_space, '  ' ]
  [ :on_pi, 'xml', 'version="1.0"' ]
  [ :on_prolog_space, '  ' ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_prolog_space, '  ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<?xml version="1.0"?><!--hoge--><!DOCTYPE hoge><?fuga?><hoge>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_comment, 'hoge' ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_pi, 'fuga', '' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<?xml version="1.0"?><!--hoge--><!DOCTYPE hoge><!--fuga--><hoge>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_comment, 'hoge' ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_comment, 'fuga' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<!--hoge--><?xml version="1.0"?><hoge>'
  [ :on_comment, 'hoge' ]
  [ :on_pi, 'xml', 'version="1.0"' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<?hoge?><?xml version="1.0"?><hoge>'
  [ :on_pi, 'hoge', '' ]
  [ :on_pi, 'xml', 'version="1.0"' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<?fuga?>  <hoge>'
  [ :on_pi, 'fuga', '' ]
  [ :on_prolog_space, '  ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<!--fuga-->  <hoge>'
  [ :on_comment, 'fuga' ]
  [ :on_prolog_space, '  ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  'hoge<?xml version="1.0"?><!DOCTYPE hoge>'
  [ :on_chardata, 'hoge' ]
  [ :on_pi, 'xml', 'version="1.0"' ]
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, "<!DOCTYPE hoge>" ]

  '>hoge<?xml version="1.0"?><!DOCTYPE hoge>'
  [ :on_chardata, '>hoge' ]
  [ :on_pi, 'xml', 'version="1.0"' ]
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, "<!DOCTYPE hoge>" ]

  '><?xml version="1.0"?><!DOCTYPE hoge>'
  [ :on_chardata, '>' ]
  [ :on_pi, 'xml', 'version="1.0"' ]
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, "<!DOCTYPE hoge>" ]

  '<?xml version="1.0"?> fuga <!DOCTYPE hoge>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_chardata, ' fuga ' ]
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, "<!DOCTYPE hoge>" ]

  '<?xml version="1.0"?><!DOCTYPE hoge><!DOCTYPE fuga><hoge>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, "<!DOCTYPE fuga>" ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  "<!DOCTYPE\fhoge>"
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, "<!DOCTYPE\fhoge>" ]

  "<?xml\fversion='1.0'?>"
  [ :on_pi, "xml\fversion='1.0'", '' ]

  "    >   <hoge>"
  [ :on_prolog_space, '    ' ]
  [ :on_chardata, '>   ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  TESTCASEEND

  def test_emptystring
    parse ""
  end

  def test_nil
    parse nil
  end

end




load "#{File.dirname($0)}/runtest.rb" if __FILE__ == $0
