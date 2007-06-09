#
# tests/namespace.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: testnamespace.rb,v 1.10 2003/02/28 12:31:07 katsu Exp $
#

require 'test/unit'
require 'deftestcase'
require 'xmlscan/namespace'
require 'visitor'


class TestXMLNamespace < Test::Unit::TestCase

  include DefTestCase

  class Visitor < RecordingVisitor.new_class(XMLScan::NSVisitor)

    def on_stag_end_ns(qname, ns)
      super qname, ns.dup
    end

    def on_stag_end_empty_ns(qname, ns)
      super qname, ns.dup
    end

  end


  private

  def setup
    @v = Visitor.new
    @s = XMLScan::XMLParserNS.new(@v)
  end

  def parse(src)
    @s.parse src
    @v.result
  end



  NS_XML   = 'http://www.w3.org/XML/1998/namespace'
  NS_XMLNS = 'http://www.w3.org/2000/xmlns/'


  public

  deftestcase 'default', <<-'TESTCASEEND'

  '<hoge xmlns="fuga"></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {''=>'fuga'} ]
  [ :on_etag, 'hoge' ]

  '<hoge xmlns="fuga"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {''=>'fuga'} ]

  '<hoge></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {} ]
  [ :on_etag, 'hoge' ]

  '<hoge/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {} ]

  '<hoge xmlns="fuga" foo="bar"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'foo', nil, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty_ns, 'hoge', {''=>'fuga'} ]

  '<hoge foo="bar" xmlns="fuga"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'foo', nil, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty_ns, 'hoge', {''=>'fuga'} ]

  '<hoge xmlns="fu&#103;a"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {''=>'fuga'} ]

  '<hoge xmlns="fu&#x67;a"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {''=>'fuga'} ]

  '<hoge xmlns="fu&foo;a"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :ns_wellformed_error, "xmlns includes undeclared entity reference" ]
  [ :on_stag_end_empty_ns, 'hoge', {''=>'fua'} ]

  '<hoge xmlns="foo"><fuga/></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {''=>'foo'} ]
  [ :on_stag_ns, 'fuga', '', 'fuga' ]
  [ :on_stag_end_empty_ns, 'fuga', {''=>'foo'} ]
  [ :on_etag, 'hoge' ]

  '<hoge xmlns="foo"><fuga xmlns="bar"/><moga/></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {''=>'foo'} ]
  [ :on_stag_ns, 'fuga', '', 'fuga' ]
  [ :on_stag_end_empty_ns, 'fuga', {''=>'bar'} ]
  [ :on_stag_ns, 'moga', '', 'moga' ]
  [ :on_stag_end_empty_ns, 'moga', {''=>'foo'} ]
  [ :on_etag, 'hoge' ]

  '<hoge xmlns="foo"><fuga xmlns=""><moga/></fuga></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {''=>'foo'} ]
  [ :on_stag_ns, 'fuga', '', 'fuga' ]
  [ :on_stag_end_ns, 'fuga', {''=>nil} ]
  [ :on_stag_ns, 'moga', '', 'moga' ]
  [ :on_stag_end_empty_ns, 'moga', {''=>nil} ]
  [ :on_etag, 'fuga' ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND



  deftestcase 'prefix', <<-'TESTCASEEND'

  '<foo:hoge xmlns:foo="fuga"></foo:hoge>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fuga'} ]
  [ :on_etag, 'foo:hoge' ]

  '<foo:hoge xmlns:foo="fuga"/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fuga'} ]

  '<foo:hoge></foo:hoge>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :ns_wellformed_error, "prefix `foo' is not declared" ]
  [ :on_stag_end_ns, 'foo:hoge', {} ]
  [ :on_etag, 'foo:hoge' ]

  '<foo:hoge/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :ns_wellformed_error, "prefix `foo' is not declared" ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {} ]

  '<foo:hoge:fuga/>'
  [ :ns_parse_error, "localpart `hoge:fuga' includes `:'" ]
  [ :on_stag_ns, 'foo:hoge:fuga', 'foo', 'hoge:fuga' ]
  [ :ns_wellformed_error, "prefix `foo' is not declared" ]
  [ :on_stag_end_empty_ns, 'foo:hoge:fuga', {} ]

  '<foo:hoge xmlns:foo="fuga" foo="bar"/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_attribute_ns, 'foo', nil, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fuga'} ]

  '<foo:hoge foo="bar" xmlns:foo="fuga"/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_attribute_ns, 'foo', nil, 'foo' ]
  [ :on_attr_value, 'bar' ]
  [ :on_attribute_end, 'foo' ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fuga'} ]

  '<bar:hoge xmlns:foo="fuga"/>'
  [ :on_stag_ns, 'bar:hoge', 'bar', 'hoge' ]
  [ :ns_wellformed_error, "prefix `bar' is not declared" ]
  [ :on_stag_end_empty_ns, 'bar:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fuga'} ]

  '<foo:hoge xmlns:foo=""/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :ns_parse_error, "`foo' is bound to empty namespace name" ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>''} ]

  '<foo:hoge xmlns:foo="fu&#103;a"/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fuga'} ]

  '<foo:hoge xmlns:foo="fu&#x67;a"/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fuga'} ]

  '<foo:hoge xmlns:foo="fu&foo;a"/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :ns_wellformed_error, "xmlns includes undeclared entity reference" ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'fua'} ]

  '<foo:hoge xmlns:foo="foo"><foo:fuga/></foo:hoge>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'foo'} ]
  [ :on_stag_ns, 'foo:fuga', 'foo', 'fuga' ]
  [ :on_stag_end_empty_ns, 'foo:fuga', {'xmlns'=>NS_XMLNS, 'foo'=>'foo'} ]
  [ :on_etag, 'foo:hoge' ]

  '<foo:hoge xmlns:foo="foo"><foo:fuga xmlns:foo="bar"/><foo:moga/></foo:hoge>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'foo'} ]
  [ :on_stag_ns, 'foo:fuga', 'foo', 'fuga' ]
  [ :on_stag_end_empty_ns, 'foo:fuga', {'xmlns'=>NS_XMLNS, 'foo'=>'bar'} ]
  [ :on_stag_ns, 'foo:moga', 'foo', 'moga' ]
  [ :on_stag_end_empty_ns, 'foo:moga', {'xmlns'=>NS_XMLNS, 'foo'=>'foo'} ]
  [ :on_etag, 'foo:hoge' ]

  '<foo:hoge xmlns:foo="foo"><foo:fuga xmlns:foo="bar"><foo:moga/></foo:fuga></foo:hoge>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'foo'} ]
  [ :on_stag_ns, 'foo:fuga', 'foo', 'fuga' ]
  [ :on_stag_end_ns, 'foo:fuga', {'xmlns'=>NS_XMLNS, 'foo'=>'bar'} ]
  [ :on_stag_ns, 'foo:moga', 'foo', 'moga' ]
  [ :on_stag_end_empty_ns, 'foo:moga', {'xmlns'=>NS_XMLNS, 'foo'=>'bar'} ]
  [ :on_etag, 'foo:fuga' ]
  [ :on_etag, 'foo:hoge' ]

  '<foo:hoge xmlns:foo="foo" xmlns:bar="bar"/>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'foo', 'bar'=>'bar'} ]

  '<foo:hoge xmlns:foo="foo" xmlns:bar="bar"><bar:fuga/></foo:hoge>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'foo', 'bar'=>'bar'} ]
  [ :on_stag_ns, 'bar:fuga', 'bar', 'fuga' ]
  [ :on_stag_end_empty_ns, 'bar:fuga', {'xmlns'=>NS_XMLNS, 'foo'=>'foo', 'bar'=>'bar'} ]
  [ :on_etag, 'foo:hoge' ]

  '<foo:hoge xmlns:foo="foo" xmlns:bar="bar"><bar:fuga xmlns:foo="baz"/><moga/></foo:hoge>'
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'foo', 'bar'=>'bar'} ]
  [ :on_stag_ns, 'bar:fuga', 'bar', 'fuga' ]
  [ :on_stag_end_empty_ns, 'bar:fuga', {'xmlns'=>NS_XMLNS, 'foo'=>'baz', 'bar'=>'bar'} ]
  [ :on_stag_ns, 'moga', '', 'moga' ]
  [ :on_stag_end_empty_ns, 'moga', {'xmlns'=>NS_XMLNS, 'foo'=>'foo', 'bar'=>'bar'} ]
  [ :on_etag, 'foo:hoge' ]

  '<hoge><foo:hoge xmlns:foo="foo" xmlns:bar="bar"/><fuga/></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {} ]
  [ :on_stag_ns, 'foo:hoge', 'foo', 'hoge' ]
  [ :on_stag_end_empty_ns, 'foo:hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'foo', 'bar'=>'bar'} ]
  [ :on_stag_ns, 'fuga', '', 'fuga' ]
  [ :on_stag_end_empty_ns, 'fuga', {'xmlns'=>NS_XMLNS, 'foo'=>nil, 'bar'=>nil} ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND



  deftestcase 'attribute', <<-'TESTCASEEND'

  '<hoge xmlns="bar" fuga="moga"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'fuga', nil, 'fuga' ]
  [ :on_attr_value, 'moga' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end_empty_ns, 'hoge', {''=>'bar'} ]

  '<hoge xmlns:foo="bar" foo:fuga="moga"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'foo:fuga', 'foo', 'fuga' ]
  [ :on_attr_value, 'moga' ]
  [ :on_attribute_end, 'foo:fuga' ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'bar'} ]

  '<hoge xmlns:foo="bar" bar:fuga="moga"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'bar:fuga', 'bar', 'fuga' ]
  [ :on_attr_value, 'moga' ]
  [ :on_attribute_end, 'bar:fuga' ]
  [ :ns_wellformed_error, "prefix `bar' is not declared" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'bar'} ]

  '<hoge xmlns:foo="bar"><fuga foo:baz="moga"/></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'bar'} ]
  [ :on_stag_ns, 'fuga', '', 'fuga' ]
  [ :on_attribute_ns, 'foo:baz', 'foo', 'baz' ]
  [ :on_attr_value, 'moga' ]
  [ :on_attribute_end, 'foo:baz' ]
  [ :on_stag_end_empty_ns, 'fuga', {'xmlns'=>NS_XMLNS, 'foo'=>'bar'} ]
  [ :on_etag, 'hoge' ]

  '<hoge xmlns:foo="bar" xmlns:bar="baz" foo:fuga="moga" bar:fuga="gema"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'foo:fuga', 'foo', 'fuga' ]
  [ :on_attr_value, 'moga' ]
  [ :on_attribute_end, 'foo:fuga' ]
  [ :on_attribute_ns, 'bar:fuga', 'bar', 'fuga' ]
  [ :on_attr_value, 'gema' ]
  [ :on_attribute_end, 'bar:fuga' ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'bar', 'bar'=>'baz'} ]

  '<hoge xmlns:foo="bar" xmlns:bar="bar" foo:fuga="moga" bar:fuga="gema"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'foo:fuga', 'foo', 'fuga' ]
  [ :on_attr_value, 'moga' ]
  [ :on_attribute_end, 'foo:fuga' ]
  [ :on_attribute_ns, 'bar:fuga', 'bar', 'fuga' ]
  [ :on_attr_value, 'gema' ]
  [ :on_attribute_end, 'bar:fuga' ]
  [ :ns_wellformed_error, "doubled localpart `fuga' in the same namespace" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'bar', 'bar'=>'bar'} ]

  '<hoge foo:fuga="moga" bar:fuga="gema" xmlns:foo="bar" xmlns:bar="bar"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'foo:fuga', 'foo', 'fuga' ]
  [ :on_attr_value, 'moga' ]
  [ :on_attribute_end, 'foo:fuga' ]
  [ :on_attribute_ns, 'bar:fuga', 'bar', 'fuga' ]
  [ :on_attr_value, 'gema' ]
  [ :on_attribute_end, 'bar:fuga' ]
  [ :ns_wellformed_error, "doubled localpart `fuga' in the same namespace" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'bar', 'bar'=>'bar'} ]

  '<hoge xmlns:foo="moga"><fuga foo:bar="a" baz:bar="a" xmlns:baz="moga"/></hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'foo'=>'moga'} ]
  [ :on_stag_ns, 'fuga', '', 'fuga' ]
  [ :on_attribute_ns, 'foo:bar', 'foo', 'bar' ]
  [ :on_attr_value, 'a' ]
  [ :on_attribute_end, 'foo:bar' ]
  [ :on_attribute_ns, 'baz:bar', 'baz', 'bar' ]
  [ :on_attr_value, 'a' ]
  [ :on_attribute_end, 'baz:bar' ]
  [ :ns_wellformed_error, "doubled localpart `bar' in the same namespace" ]
  [ :on_stag_end_empty_ns, 'fuga', {'xmlns'=>NS_XMLNS, 'foo'=>'moga', 'baz'=>'moga'} ]
  [ :on_etag, 'hoge' ]

  '<foo foo:bar:fuga="hoge" xmlns:foo="bar" xmlns:bar="bar"/>'
  [ :on_stag_ns, 'foo', '', 'foo' ]
  [ :ns_parse_error, "localpart `bar:fuga' includes `:'" ]
  [ :on_attribute_ns, 'foo:bar:fuga', 'foo', 'bar:fuga' ]
  [ :on_attr_value, 'hoge' ]
  [ :on_attribute_end, 'foo:bar:fuga' ]
  [ :on_stag_end_empty_ns, 'foo', {'xmlns'=>NS_XMLNS, 'foo'=>'bar', 'bar'=>'bar'} ]

  TESTCASEEND



  deftestcase 'reserved', <<-'TESTCASEEND'

  '<hoge xml:lang="ja"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'xml:lang', 'xml', 'lang' ]
  [ :on_attr_value, 'ja' ]
  [ :on_attribute_end, 'xml:lang' ]
  [ :on_stag_end_empty_ns, 'hoge', {'xml'=>NS_XML} ]

  '<foo><bar><baz xml:lang="ja"/></bar><hoge/></foo>'
  [ :on_stag_ns, 'foo', '', 'foo' ]
  [ :on_stag_end_ns, 'foo', {} ]
  [ :on_stag_ns, 'bar', '', 'bar' ]
  [ :on_stag_end_ns, 'bar', {} ]
  [ :on_stag_ns, 'baz', '', 'baz' ]
  [ :on_attribute_ns, 'xml:lang', 'xml', 'lang' ]
  [ :on_attr_value, 'ja' ]
  [ :on_attribute_end, 'xml:lang' ]
  [ :on_stag_end_empty_ns, 'baz', {'xml'=>NS_XML} ]
  [ :on_etag, 'bar' ]
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {'xml'=>NS_XML} ]
  [ :on_etag, 'foo' ]

  '<xmlns:hoge/>'
  [ :ns_wellformed_error, "prefix `xmlns' is not used for namespace prefix declaration" ]
  [ :on_stag_ns, 'xmlns:hoge', 'xmlns', 'hoge' ]
  [ :on_stag_end_empty_ns, 'xmlns:hoge', {'xmlns'=>NS_XMLNS} ]

  '<hoge xmlns:xml="fuga"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :ns_wellformed_error, "prefix `xml' can't be bound to any namespace except `http://www.w3.org/XML/1998/namespace'" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'xml'=>'fuga'} ]

  '<hoge xmlns:xml="http://www.w3.org/XML/1998/namespace"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'xml'=>NS_XML} ]

  '<hoge xmlns:fuga="http://www.w3.org/XML/1998/namespace"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :ns_wellformed_error, "namespace `http://www.w3.org/XML/1998/namespace' is reserved for prefix `xml'" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'fuga'=>NS_XML} ]

  '<hoge xmlns:xmlns="fuga"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :ns_wellformed_error, "prefix `xmlns' can't be bound to any namespace explicitly" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>'fuga'} ]

  '<hoge xmlns:xmlns="http://www.w3.org/2000/xmlns/"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :ns_wellformed_error, "prefix `xmlns' can't be bound to any namespace explicitly" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS} ]

  '<hoge xmlns:fuga="http://www.w3.org/2000/xmlns/"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :ns_wellformed_error, "namespace `http://www.w3.org/2000/xmlns/' is reserved for prefix `xmlns'" ]
  [ :on_stag_end_empty_ns, 'hoge', {'xmlns'=>NS_XMLNS, 'fuga'=>NS_XMLNS} ]

  TESTCASEEND



  deftestcase 'wellformedness', <<-'TESTCASEEND'

  '<!DOCTYPE foo:bar><hoge/>'
  [ :on_doctype, 'foo:bar', nil, nil ]
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {} ]

  '<!DOCTYPE foo:bar:baz><hoge/>'
  [ :ns_parse_error, "qualified name `foo:bar:baz' includes `:'" ]
  [ :on_doctype, 'foo:bar:baz', nil, nil ]
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {} ]

  '<?foo?><hoge/>'
  [ :on_pi, 'foo', '' ]
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {} ]

  '<?foo:bar?><hoge/>'
  [ :ns_parse_error, "PI target `foo:bar' includes `:'" ]
  [ :on_pi, 'foo:bar', '' ]
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_empty_ns, 'hoge', {} ]

  '<hoge fuga="&foo:bar;"/>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_attribute_ns, 'fuga', nil, 'fuga' ]
  [ :ns_parse_error, "entity reference `foo:bar' includes `:'" ]
  [ :on_attr_entityref, 'foo:bar' ]
  [ :on_attribute_end, 'fuga' ]
  [ :on_stag_end_empty_ns, 'hoge', {} ]

  '<hoge>&foo:bar;</hoge>'
  [ :on_stag_ns, 'hoge', '', 'hoge' ]
  [ :on_stag_end_ns, 'hoge', {} ]
  [ :ns_parse_error, "entity reference `foo:bar' includes `:'" ]
  [ :on_entityref, 'foo:bar' ]
  [ :on_etag, 'hoge' ]

  TESTCASEEND





end




load "#{File.dirname($0)}/runtest.rb" if __FILE__ == $0
