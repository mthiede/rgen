#
# tests/testparser.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: testparser.rb,v 1.16 2003/02/28 12:31:07 katsu Exp $
#

require 'test/unit'
require 'deftestcase'
require 'xmlscan/parser'
require 'visitor'


class TestXMLParser < Test::Unit::TestCase

  include DefTestCase

  Visitor = RecordingVisitor.new_class(XMLScan::Visitor)


  private

  def setup
    @v = Visitor.new
    @s = XMLScan::XMLParser.new(@v)
  end

  def parse(src)
    @s.parse src
    @v.result
  end


  public

  deftestcase 'xmldecl', <<-'TESTCASEEND'

  '<?xml version="1.0" ?><hoge/>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<?xml version="1.01" ?><hoge/>'
  [ :on_xmldecl ]
  [ :warning, "unsupported XML version `1.01'" ]
  [ :on_xmldecl_version, '1.01' ]
  [ :on_xmldecl_end ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<?xml version="1.0" standalone="yes" ?><hoge/>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_standalone, 'yes' ]
  [ :on_xmldecl_end ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<?xml version="1.0" standalone="no" ?><hoge/>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_standalone, 'no' ]
  [ :on_xmldecl_end ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<?xml version="1.0" standalone="hoge" ?><hoge/>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :parse_error, "standalone declaration must be either `yes' or `no'" ]
  [ :on_xmldecl_standalone, 'hoge' ]
  [ :on_xmldecl_end ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<?xml version="1.0" standalone="YES" ?><hoge/>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :parse_error, "standalone declaration must be either `yes' or `no'" ]
  [ :on_xmldecl_standalone, 'YES' ]
  [ :on_xmldecl_end ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  TESTCASEEND



  deftestcase 'doctype', <<-'TESTCASEEND'

  '<!DOCTYPE hoge PUBLIC "foo" "bar"><hoge/>'
  [ :on_doctype, 'hoge', 'foo', 'bar' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<!DOCTYPE hoge PUBLIC "foo"><hoge/>'
  [ :parse_error, "public external ID must have both public ID and system ID" ]
  [ :on_doctype, 'hoge', 'foo', nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<!DOCTYPE hoge SYSTEM "foo"><hoge/>'
  [ :on_doctype, 'hoge', nil, 'foo' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  TESTCASEEND



  deftestcase 'ignore_space', <<-'TESTCASEEND'

  '<?xml version="1.0"?>  <!DOCTYPE hoge>  <hoge/>'
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<?xml version="1.0"?>  <!DOCTYPE hoge>  <hoge/>  '
  [ :on_xmldecl ]
  [ :on_xmldecl_version, '1.0' ]
  [ :on_xmldecl_end ]
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '  <!DOCTYPE hoge>  <hoge>  </hoge>  '
  [ :on_doctype, 'hoge', nil, nil ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, '  ' ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND



  deftestcase 'pi', <<-'TESTCASEEND'

  ' <?xml ?><hoge/>'
  [ :parse_error, "reserved PI target `xml'" ]
  [ :on_pi, 'xml', '' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  ' <?Xml ?><hoge/>'
  [ :parse_error, "reserved PI target `Xml'" ]
  [ :on_pi, 'Xml', '' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  ' <?XML ?><hoge/>'
  [ :parse_error, "reserved PI target `XML'" ]
  [ :on_pi, 'XML', '' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  TESTCASEEND




  deftestcase 'element_nesting', <<-'TESTCASEEND'

  '<hoge></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<hoge><fuga></fuga></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]
  [ :on_etag, 'fuga' ]
  [ :on_etag, 'hoge' ]

  '<hoge><fuga/></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end_empty, 'fuga' ]
  [ :on_etag, 'hoge' ]

  '<hoge/>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<hoge><fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]
  [ :parse_error, "unclosed element `fuga' meets EOF" ]
  [ :on_etag, 'fuga' ]
  [ :parse_error, "unclosed element `hoge' meets EOF" ]
  [ :on_etag, 'hoge' ]

  '<hoge><fuga></fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]
  [ :on_etag, 'fuga' ]
  [ :parse_error, "unclosed element `hoge' meets EOF" ]
  [ :on_etag, 'hoge' ]

  '<hoge><fuga></hoge></fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]
  [ :wellformed_error, "element type `hoge' is not matched" ]
  [ :on_etag, 'fuga' ]
  [ :wellformed_error, "element type `fuga' is not matched" ]
  [ :on_etag, 'hoge' ]

  '<hoge></fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :wellformed_error, "element type `fuga' is not matched" ]
  [ :on_etag, 'hoge' ]

  '</hoge>'
  [ :parse_error, "end tag `hoge' appears alone" ]
  [ :parse_error, "no root element was found" ]

  '<hoge></hoge><fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]
  [ :parse_error, "another root element is found" ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]
  [ :parse_error, "unclosed element `fuga' meets EOF" ]
  [ :on_etag, 'fuga' ]

  '<hoge></hoge></fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]
  [ :parse_error, "end tag `fuga' appears alone" ]

  '<hoge/><fuga/>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end_empty, 'hoge' ]
  [ :parse_error, "another root element is found" ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end_empty, 'fuga' ]

  TESTCASEEND



  deftestcase 'outside', <<-'TESTCASEEND'

  '<hoge>fuga</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'fuga' ]
  [ :on_etag, 'hoge' ]

  '  <hoge>fuga</hoge>  '
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'fuga' ]
  [ :on_etag, 'hoge' ]

  '<hoge><![CDATA[fuga]]></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_cdata, 'fuga' ]
  [ :on_etag, 'hoge' ]

  'fuga<hoge></hoge>'
  [ :parse_error, "content of element is found outside of root element" ]
  [ :on_chardata, 'fuga' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<![CDATA[fuga]]><hoge></hoge>'
  [ :parse_error, "CDATA section is found outside of root element" ]
  [ :on_cdata, 'fuga' ]
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<hoge></hoge>fuga'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]
  [ :parse_error, "content of element is found outside of root element" ]
  [ :on_chardata, 'fuga' ]

  '<hoge></hoge><![CDATA[fuga]]>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]
  [ :parse_error, "CDATA section is found outside of root element" ]
  [ :on_cdata, 'fuga' ]

  '<hoge></hoge><fuga>foo</fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]
  [ :parse_error, "another root element is found" ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]
  [ :on_chardata, 'foo' ]
  [ :on_etag, 'fuga' ]

  '<hoge></hoge><fuga><![CDATA[fuga]]></fuga>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]
  [ :parse_error, "another root element is found" ]
  [ :on_stag, 'fuga' ]
  [ :on_stag_end, 'fuga' ]
  [ :on_cdata, 'fuga' ]
  [ :on_etag, 'fuga' ]

  TESTCASEEND



  deftestcase 'entityref', <<-'TESTCASEEND'

  '<hoge>foo&lt;bar</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'foo' ]
  [ :on_entityref, 'lt' ]
  [ :on_chardata, 'bar' ]
  [ :on_etag, 'hoge' ]

  '<hoge>foo&gt;bar</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'foo' ]
  [ :on_entityref, 'gt' ]
  [ :on_chardata, 'bar' ]
  [ :on_etag, 'hoge' ]

  '<hoge>foo&amp;bar</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'foo' ]
  [ :on_entityref, 'amp' ]
  [ :on_chardata, 'bar' ]
  [ :on_etag, 'hoge' ]

  '<hoge>foo&quot;bar</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'foo' ]
  [ :on_entityref, 'quot' ]
  [ :on_chardata, 'bar' ]
  [ :on_etag, 'hoge' ]

  '<hoge>foo&apos;bar</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'foo' ]
  [ :on_entityref, 'apos' ]
  [ :on_chardata, 'bar' ]
  [ :on_etag, 'hoge' ]

  '<hoge>foo&fuga;bar</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'foo' ]
  [ :on_entityref, 'fuga' ]
  [ :on_chardata, 'bar' ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND



  deftestcase 'charref', <<-'TESTCASEEND'

  '<hoge>fu&#103;a</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'fu' ]
  [ :on_charref, 103 ]
  [ :on_chardata, 'a' ]
  [ :on_etag, 'hoge' ]

  '<hoge>fu&#x67;a</hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_chardata, 'fu' ]
  [ :on_charref_hex, 103 ]
  [ :on_chardata, 'a' ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND



  deftestcase 'attr_entityref', <<-'TESTCASEEND'

  '<hoge fuga="foo&lt;bar"></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, 'foo' ]
  [ :on_attr_entityref, 'lt' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<hoge fuga="foo&gt;bar"></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, 'foo' ]
  [ :on_attr_entityref, 'gt' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<hoge fuga="foo&amp;bar"></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, 'foo' ]
  [ :on_attr_entityref, 'amp' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<hoge fuga="foo&quot;bar"></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, 'foo' ]
  [ :on_attr_entityref, 'quot' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<hoge fuga="foo&apos;bar"></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, 'foo' ]
  [ :on_attr_entityref, 'apos' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  '<hoge fuga="foo&HOGE;bar"></hoge>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, 'foo' ]
  [ :on_attr_entityref, 'HOGE' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND



  deftestcase 'attr_charref', <<-'TESTCASEEND'

  '<hoge foo="fu&#103;a"/>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'fu' ]
  [ :on_attr_charref, 103 ]
  [ :on_attr_value, 'a' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<hoge foo="fu&#x67;a"/>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'fu' ]
  [ :on_attr_charref_hex, 103 ]
  [ :on_attr_value, 'a' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty, 'hoge' ]

  TESTCASEEND



  deftestcase 'normalize', <<-'TESTCASEEND'

  "<hoge fuga=' foo bar '></hoge>"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, ' foo bar ' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  "<hoge fuga='\tfoo\nbar\t'></hoge>"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, ' foo bar ' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  "<hoge fuga='\tfoo\r\nbar\t'></hoge>"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, ' foo  bar ' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  "<hoge fuga='\tfoo\r\nbar\t'></hoge>"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, ' foo  bar ' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  "<hoge fuga='\tfoo&#9;bar\t'></hoge>"
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'fuga' ]
  [ :on_attr_value, ' foo' ]
  [ :on_attr_charref, 9 ]
  [ :on_attr_value, 'bar ' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end, 'hoge' ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND



  deftestcase 'attribute', <<-'TESTCASEEND'

  '<hoge foo="bar" bar="fuga"/>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_attribute, 'bar' ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'bar' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<hoge foo="bar" foo="fuga"/>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :wellformed_error, "doubled attribute `foo'" ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty, 'hoge' ]

  '<hoge foo="bar" foo="fuga" foo="hoge"/>'
  [ :on_stag, 'hoge' ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :wellformed_error, "doubled attribute `foo'" ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'fuga' ]
  [ :on_attribute_end, 'foo' ]
  [ :wellformed_error, "doubled attribute `foo'" ]
  [ :on_attribute, 'foo' ]
  [ :on_attr_value, 'hoge' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty, 'hoge' ]

  TESTCASEEND

end




load "#{File.dirname($0)}/runtest.rb" if __FILE__ == $0
