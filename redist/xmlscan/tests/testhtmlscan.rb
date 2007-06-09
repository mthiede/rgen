#
# tests/testhtmlscan.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: testhtmlscan.rb,v 1.19 2003/02/28 12:31:07 katsu Exp $
#

require 'test/unit'
require 'deftestcase'
require 'xmlscan/htmlscan'
require 'visitor'


class TestHTMLScanner < Test::Unit::TestCase

  include DefTestCase

  Visitor = RecordingVisitor.new_class(XMLScan::Visitor)


  private

  def setup
    @v = Visitor.new
    @s = XMLScan::HTMLScanner.new(@v)
  end

  def parse(src)
    @s.parse src
    @v.result
  end


  public

  deftestcase 'html_comment', <<-'TESTCASEEND'

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

  '<!-- hoge -- -- fuga -->'
  [ :on_comment, ' hoge -- -- fuga ' ]

  '<!-- hoge--fuga -->'
  [ :parse_error, "only whitespace can appear between two comments" ]
  [ :on_comment, ' hoge--fuga ' ]

  '<!-- hoge--fuga'
  [ :parse_error, "only whitespace can appear between two comments" ]
  [ :parse_error, 'unterminated comment meets EOF' ]
  [ :on_comment, ' hoge--fuga' ]

  # should be parsed as |<!--|- hogefuga |--|->|
  '<!--- hogefuga --->'
  [ :parse_error, "only whitespace can appear between two comments"]
  [ :parse_error, "`-->' is found but comment must not end here"]
  [ :on_comment, '- hogefuga -' ]

  '<!--- hogefuga --- >'
  [ :parse_error, "only whitespace can appear between two comments"]
  [ :parse_error, "`-->' is found but comment must not end here"]
  [ :on_comment, '- hogefuga -' ]

  # should be parsed as |<!--|--|--|-->|
  '<!-------->'
  [ :on_comment, '----' ]

  # should be parsed as |<!--|--|--|->|
  '<!------->'
  [ :parse_error, "`-->' is found but comment must not end here"]
  [ :on_comment, '---' ]

  # should be parsed as |<!--|--|--|>|
  '<!------>'
  [ :parse_error, "`-->' is found but comment must not end here"]
  [ :on_comment, '--' ]

  # should be parsed as |<!--|--|->|
  '<!----->'
  [ :parse_error, "only whitespace can appear between two comments"]
  [ :parse_error, "`-->' is found but comment must not end here"]
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

  '<!--hoge--  >fuga'
  [ :on_comment, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<!--hoge-->>'
  [ :on_comment, 'hoge' ]
  [ :on_chardata, '>' ]

  '<!--hoge--fuga-->hoge'
  [ :parse_error, "only whitespace can appear between two comments"]
  [ :on_comment, 'hoge--fuga' ]
  [ :on_chardata, 'hoge' ]

  TESTCASEEND



  deftestcase 'pi', <<-'TESTCASEEND'

  '<?hoge fuga?>'
  [ :on_pi, '', 'hoge fuga?' ]

  '<?xml version="1.0"?>'
  [ :on_pi, '', 'xml version="1.0"?' ]

  '<?hoge fuga>'
  [ :on_pi, '', 'hoge fuga' ]

  '<?hoge  >'
  [ :on_pi, '', 'hoge  '  ]

  '<?hoge>'
  [ :on_pi, '', 'hoge' ]

  '<?hoge <<a<<<a<<<   >'
  [ :on_pi, '', 'hoge <<a<<<a<<<   ' ]

  '<?hoge<>'
  [ :on_pi, '', 'hoge<' ]

  '<? >'
  [ :on_pi, '', ' ' ]

  '<?>'
  [ :on_pi, '', '' ]

  '<?'
  [ :parse_error, "unterminated PI meets EOF" ]
  [ :on_pi, '', '' ]

  '<?hoge>fuga'
  [ :on_pi, '', 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<?hoge>>'
  [ :on_pi, '', 'hoge' ]
  [ :on_chardata, '>' ]

  TESTCASEEND



  deftestcase 'stag', <<-'TESTCASEEND'

  '<hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge     >'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

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

  '< hoge>fuga'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '< hoge>' ]
  [ :on_chardata, 'fuga' ]

  '< hoge>>'
  [ :parse_error, "parse error at `<'" ]
  [ :on_chardata, '< hoge>' ]
  [ :on_chardata, '>' ]

  '<hoge/>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge/>fuga'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'fuga' ]

  '<hoge/>>'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, '>' ]

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

  "<hoge foo =  '  bar  ' HOGE = 'FUGA'  >"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, '  bar  ' ]
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
  [ :parse_error, "parse error at `/'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo=bar/>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar/' ]
  [ :on_attribute_end, 'foo' ]
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
  [ :on_attr_value, '<a' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'b' ]
  [ :on_attr_value, '<c' ]
  [ :on_attr_value, '>' ]
  [ :on_attr_value, 'ar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo=bar>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   =   bar   >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   =   bar&fuga;bar   >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar&fuga;bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   = bar/baz%fuga  >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar/baz%fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo/bar   = bar/baz%fuga  >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'foo' ]
  [ :on_attribute_end, nil ]
  [ :parse_error, "parse error at `/'" ]
  [ :on_attribute, 'bar' ]
  [ :on_attr_value, 'bar/baz%fuga' ]
  [ :on_attribute_end, 'bar' ]
  [ :on_stag_end, 'hoge' ]


  '<hoge   foo   =   bar  hoge = fuga  >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_attribute, 'hoge' ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'foo' ]
  [ :on_attribute_end, nil ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo  bar  >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'foo' ]
  [ :on_attribute_end, nil ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, nil ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo&hoge;bar>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'foo&hoge;bar' ]
  [ :on_attribute_end, nil ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   =   bar  hoge >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'hoge' ]
  [ :on_attribute_end, nil ]
  [ :on_stag_end, 'hoge' ]

  '<hoge   foo   =   bar<fuga   >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "unclosed start tag `hoge' meets another tag" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]

  '<hoge foo="bar"HOGE ="FUGA">'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_attribute, 'HOGE' ]
  [ :on_attr_value, 'FUGA' ]
  [ :on_attribute_end, 'HOGE' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo=bar=fuga >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "parse error at `='" ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, nil ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo="bar" <fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "unclosed start tag `hoge' meets another tag" ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]

  '<hoge foo="bar>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attr_value, '>' ]
  [ :parse_error, "unterminated attribute `foo' meets EOF" ]
  [ :on_attribute_end, 'foo' ]
  [ :parse_error, "unclosed start tag `hoge' meets EOF" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge foo= >'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'foo' ]
  [ :on_attribute_end, nil ]
  [ :parse_error, "parse error at `='" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge ="fuga" >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `='" ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, nil ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge "fuga" >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, nil ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge"fuga" >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, nil ]
  [ :parse_error, "parse error at `\"'" ]
  [ :on_stag_end, 'hoge' ]

  '<hoge = fuga >'
  [ :on_stag, 'hoge' ]
  [ :parse_error, "parse error at `='" ]
  [ :on_attribute, nil ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, nil ]
  [ :on_stag_end, 'hoge' ]

  TESTCASEEND



  deftestcase 'bang_tag', <<-'TESTCASEEND'

  '<!hoge>'
  [ :parse_error, "parse error at `<!'" ]

  '<!hoge fuga>'
  [ :parse_error, "parse error at `<!'" ]

  '<!hoge'
  [ :parse_error, "parse error at `<!'" ]

  '<!>'
  [ :on_comment, '' ]

  '<!'
  [ :parse_error, "parse error at `<!'" ]

  '<!hoge>fuga'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, 'fuga' ]

  '<!hoge>>'
  [ :parse_error, "parse error at `<!'" ]
  [ :on_chardata, '>' ]

  TESTCASEEND



  deftestcase 'internal_dtd', <<-'TESTCASEEND'

  '<!DOCTYPE hoge[ <!ENTITY fuga "hoge"> ]>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :parse_error, "DTD subset is found but it is not permitted in HTML" ]

  TESTCASEEND



  deftestcase 'doctype', <<-'TESTCASEEND'

  '<!DOCTYPE hoge public "fuga">'
  [ :on_doctype, 'hoge', 'fuga', nil ]

  '<!DOCTYPE hoge system "fuga">'
  [ :on_doctype, 'hoge', nil, 'fuga' ]

  '<!DOCTYPE hoge PuBliC "fuga">'
  [ :on_doctype, 'hoge', 'fuga', nil ]

  '<!DOCTYPE hoge sYsTEm "fuga">'
  [ :on_doctype, 'hoge', nil, 'fuga' ]

  TESTCASEEND



  deftestcase 'prolog', <<-'TESTCASEEND'

  '<!DOCTYPE hoge><hoge>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<!doctype hoge><hoge>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<!dOcTyPe hoge><hoge>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<hoge><!DOCTYPE hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :parse_error, "parse error at `<!'" ]

  '  <!DOCTYPE hoge>  <hoge>'
  [ :on_prolog_space, '  ' ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_prolog_space, '  ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<!--hoge--><!DOCTYPE hoge><?fuga?><hoge>'
  [ :on_comment, 'hoge' ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_pi, '', 'fuga?' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<!--hoge--><!DOCTYPE hoge><!--fuga--><hoge>'
  [ :on_comment, 'hoge' ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_comment, 'fuga' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<!--hoge-->  <hoge>'
  [ :on_comment, 'hoge' ]
  [ :on_prolog_space, '  ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  '<?hoge?>  <hoge>'
  [ :on_pi, '', 'hoge?' ]
  [ :on_prolog_space, '  ' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  'hoge<!DOCTYPE hoge>'
  [ :on_chardata, 'hoge' ]
  [ :parse_error, "parse error at `<!'" ]

  '>hoge<!DOCTYPE hoge>'
  [ :on_chardata, '>hoge' ]
  [ :parse_error, "parse error at `<!'" ]

  '<?hoge?> fuga <!DOCTYPE hoge>'
  [ :on_pi, '', 'hoge?' ]
  [ :on_chardata, ' fuga ' ]
  [ :parse_error, "parse error at `<!'" ]

  '<!DOCTYPE hoge><!DOCTYPE fuga><hoge>'
  [ :on_doctype, 'hoge', nil, nil ]
  [ :parse_error, "another document type declaration is found" ]
  [ :on_doctype, 'fuga', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]

  TESTCASEEND

end


class TestHTMLScannerCDATA < Test::Unit::TestCase

  include DefTestCase

  class CDATAContentTestVisitor < TestHTMLScanner::Visitor
    def make_scanner
      @scanner = XMLScan::HTMLScanner.new(self)
    end
    def on_stag_end(name)
      super
      s = @scanner.get_cdata_content
      @result.push [ :cdata_content, s ]
    end
  end


  private

  def setup
    @v = CDATAContentTestVisitor.new
    @s = @v.make_scanner
  end

  def parse(src)
    @s.parse src
    @v.result
  end


  public

  deftestcase 'cdata_content', <<-'TESTCASEEND'

  '<hoge>fuga</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :cdata_content, 'fuga' ]
  [ :on_etag, 'hoge' ]

  '<hoge>fuga<foo><bar>fuga</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :cdata_content, 'fuga<foo><bar>fuga' ]
  [ :on_etag, 'hoge' ]

  '<hoge>><><><<><a><>><></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :cdata_content, '><><><<><a><>><>' ]
  [ :on_etag, 'hoge' ]

  '<hoge>fuga</'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :cdata_content, 'fuga' ]
  [ :parse_error, "parse error at `</'" ]
  [ :on_chardata, '</' ]

  '<hoge>fuga<'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :cdata_content, 'fuga<' ]

  '<hoge>fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :cdata_content, 'fuga>' ]

  TESTCASEEND

end




load "#{File.dirname($0)}/runtest.rb" if __FILE__ == $0
