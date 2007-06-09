=begin
# $Id: manual.rd.src,v 1.1 2003/01/22 16:41:45 katsu Exp $

= xmlscan version 0.2 Reference Manual

This is a broken English version. If you find lexical or
grammatical mistakes, or strange expressions (including kidding,
unnatural or unclear ones) in this document, please
((<let me know|URL:mailto:katsu@blue.sky.or.jp>)).

== Abstract

XMLscan is one of non-validating XML parser written in 100%
pure Ruby.

XMLscan's features are as follows:

: 100% pure Ruby
    XMLscan doesn't require any extension libraries, so
    it completely works only with a Ruby interpreter version
    1.6 or above.
    (It also needs no standard-bundled extension library.)

: Compliant to the specification
    XMLscan has been developed to satisfy all conditions,
    described in XML 1.0 Specification and required to a
    non-validating XML processor

: High-speed
    XMLscan is, probably, the fastest parser among all
    existing XML/HTML parsers written in pure Ruby.

: Support for various CES.
    XMLscan can parse an XML document encoded in at least
    iso-8859-*, EUC-*, Shift_JIS, and UTF-8 as it is.
    UTF-16 is not supported directly, though.

: Just parsing
    The role of xmlscan is just to parse an XML document.
    XMLscan doesn't provide high-level features to easily
    handle an XML document. XMLscan is assumed to be used as
    a core part of a library providing such features.

: HTML
    XMLscan contains htmlscan, an HTML parser.


== Character encodings

By default, the value of global variable $KCODE decides
which CES (character encoding scheme) is assumed for xmlscan
to parse an XML document.
You need to set $KCODE or ((<XMLScan::XMLScanner#kcode=>))
an appropriate value to parse an XML document encoded in EUC-*,
Shift_JIS, or UTF-8.

UTF-16 is not supported directly. You should convert it into
UTF-8 before parsing.


== XML Namespaces

XML Namespaces have been already implemented in
xmlscan/namespace.rb. However, since its interface is going
to be modified, this feature is undocumented now.



== Class Reference


=== XMLScan::Error

The superclass for all exceptions related to xmlscan.

These exceptions are raised by XMLScan::Visitor
by default when it receives an error report from a parser,
such as XMLScan::XMLScanner or XMLScan::XMLParser.
Each parser never raises these exceptions by itself.

#The following exceptions are defined in xmlscan/scanner.rb:

: XMLScan::ParseError

    An error except a constraint violation, for example,
    an XML document is unmatched with a production.

: XMLScan::NotWellFormedError

    Raised when an XML document violates an well-formedness
    constraint.

: XMLScan::NotValidError

    Raised when an XML document violates an validity constraint.


=== XMLScan::Visitor

Mix-in for receiving the result of parsing an XML document.

Each parser included in xmlscan parses an XML document from
the beginning, and calls each specific method of given instance of
XMLScan::Visitor for each syntactic element, such as a tag.
It is ensured that these calls is in order of the appearance
in the document from the beginning.

==== Methods:

Without special notice, the following methods do nothing by
default.

--- XMLScan::Visitor#parse_error(msg)

    Called when the parser meets an error except a constraint
    violation, for example, an XML document is unmatched with
    a production. By default, this method raises
    ((<XMLScan::ParseError>)) exception. If no exception is
    raised and this method returns normally, the parser recovers
    the error and continues to parse.

--- XMLScan::Visitor#wellformed_error(msg)

    Called when the parser meets an well-formedness constraint
    violation. By default, this method raises
    ((<XMLScan::NotWellFormedError>)) exception. If no exception
    is raised and this method returns normally, the parser recovers
    the error and continues to parse.

--- XMLScan::Visitor#valid_error(msg)

    Called when the parser meets validity constraint
    violation. By default, this method raises
    ((<XMLScan::NotValidError>)) exception. If no exception
    is raised and this method returns normally, the parser recovers
    the error and continues to parse.

    FYI, current version of xmlscan includes no validating XML
    processor. This method is reserved for future versions.

--- XMLScan::Visitor#warning(msg)

    Called when the parser meets a non-error but unrecommended
    thing or a syntax which xmlscan is not able to parse.

--- XMLScan::Visitor#on_start_document

    Called just before the parser starts parsing an XML document.
    After this method is called, corresponding
    ((<XMLScan::Visitor#on_end_document>)) method is always called.

--- XMLScan::Visitor#on_end_document

    Called after the parser reaches the end of an XML document.

--- XMLScan::Visitor#on_xmldecl
--- XMLScan::Visitor#on_xmldecl_version(str)
--- XMLScan::Visitor#on_xmldecl_encoding(str)
--- XMLScan::Visitor#on_xmldecl_standalone(str)
--- XMLScan::Visitor#on_xmldecl_other(name, value)
--- XMLScan::Visitor#on_xmldecl_end

    Called when the parser meets an XML declaration.

        <?xml version="1.0" encoding="euc-jp" standalone="yes" ?>
        ^     ^             ^                 ^                ^
        1     2             3                 4                5

                     method                 argument
                 --------------------------------------
                  1: on_xmldecl
                  2: on_xmldecl_version     ("1.0")
                  3: on_xmldecl_encoding    ("euc-jp")
                  4: on_xmldecl_standalone  ("yes")
                  5: on_xmldecl_end

    When an XML declaration is found, both on_xmldecl and
    on_xmldecl_end method are always called. Any other methods
    are called only when the corresponding syntaxes are found.

    When a declaration except version, encoding, and standalone
    is found in an XML declaration, on_xmldecl_other method is
    called. Since such a declaration is not permitted, note that
    the parser always calls ((<XMLScan::Visitor#parse_error>)) method
    before calling on_xmldecl_other method.

--- XMLScan::Visitor#on_doctype(root, pubid, sysid)

    Called when the parser meets a document type declaration.

             document                            argument
        --------------------------------------------------------------
         1: <!DOCTYPE foo>                      ('foo', nil,   nil)
         2: <!DOCTYPE foo SYSTEM "bar">         ('foo', nil,   'bar')
         3: <!DOCTYPE foo PUBLIC "bar">         ('foo', 'bar',  nil )
         4: <!DOCTYPE foo PUBLIC "bar" "baz">   ('foo', 'bar', 'baz')

--- XMLScan::Visitor#on_prolog_space(str)

    Called when the parser meets whitespaces in prolog.

--- XMLScan::Visitor#on_comment(str)

    Called when the parser meets a comment.

--- XMLScan::Visitor#on_pi(target, pi)

    Called when the parser meets a processing instruction.

--- XMLScan::Visitor#on_chardata(str)

    Called when the parser meets character data.

--- XMLScan::Visitor#on_cdata(str)

    Called when the parser meets a CDATA section.

--- XMLScan::Visitor#on_entityref(ref)

    Called when the parser meets a general entity reference
    in a place except an attribute value.

--- XMLScan::Visitor#on_charref(code)
--- XMLScan::Visitor#on_charref_hex(code)

    Called when the parser meets a character reference
    in a place except an attribute value.
    When the character code is represented by decimals,
    on_charref is called. When by hexadecimals, on_charref_hex
    is called. ((|code|)) is an integer.

--- XMLScan::Visitor#on_stag(name)
--- XMLScan::Visitor#on_attribute(name)
--- XMLScan::Visitor#on_attr_value(str)
--- XMLScan::Visitor#on_attr_entityref(ref)
--- XMLScan::Visitor#on_attr_charref(code)
--- XMLScan::Visitor#on_attr_charref_hex(code)
--- XMLScan::Visitor#on_attribute_end(name)
--- XMLScan::Visitor#on_stag_end_empty(name)
--- XMLScan::Visitor#on_stag_end(name)

    Called when the parser meets an XML declaration.

        <hoge fuga="foo&bar;&#38;&#x26;baz"  >
        ^     ^     ^  ^    ^    ^     ^  ^  ^
        1     2     3  4    5    6     7  8  9

             method                 argument
         ------------------------------------
          1: on_stag                ('hoge')
          2: on_attribute           ('fuga')
          3: on_attr_value          ('foo')
          4: on_attr_entityref      ('bar')
          5: on_attr_charref        (38)
          6: on_attr_charref_hex    (38)
          7: on_attr_value          ('baz')
          8: on_attribute_end       ('fuga')
          9: on_stag_end            ('hoge')
              or
             on_stag_end_empty      ('hoge')

    When a start tag is found, both on_stag and corresponding
    either on_stag_end or on_stag_end_empty method are always
    called. Any other methods are called only when at least one
    attribute is found in the start tag.

    When an attribute is found, both on_attribute and
    on_attribute_end method are always called. If the attribute
    value is empty, only these two methods are called.

    When the parser meets a general entity reference in an
    attribute value, it calls on_attr_entityref method.
    When the parser meets a character reference in an attribute
    value, it calls either on_charref or on_charref_hex method.

    If the tag is an empty element tag, on_stag_end_empty method
    is called instead of on_stag_end method.

--- XMLScan::Visitor#on_etag(name)

    Called when the parser meets an end tag.



=== XMLScan::XMLScanner

The scanner which tokenizes an XML document and recognize tags,
and so on.

The conformance of XMLScan::XMLScanner to the specification
is described in another document.

==== SuperClass:

* Object

==== Class Methods:

--- XMLScan::XMLScanner.new(visitor[, option ...])

    Creates an instance. ((|visitor|)) is a instance of
    ((<XMLScan::Visitor>)) and receives the result of parsing
    from the XMLScan::Scanner object.

    You can specify one of more ((|option|)) as a string or symbol.
    XMLScan::Scanner's options are as follows:

    : 'strict_char'

        This option is enabled after
        (({require 'xmlscan/xmlchar'})).
        XMLScan::Scanner checks whether an XML document includes
        an illegal character. The performance decreases sharply.

==== Methods:

--- XMLScan::XMLScanner#kcode= arg

    Sets CES. Available values for ((|code|)) are same as $KCODE
    except nil. If ((|code|)) is nil, $KCODE decides the CES.

--- XMLScan::XMLScanner#kcode

    Returns CES. The format of the return value is same as
    Regexp#kcode. If this method returns nil, it represents that
    $KCODE decides the CES.

--- XMLScan::XMLScanner#parse(source)

    Parses ((|source|)) as an XML document. ((|source|)) must be
    a string, an array of strings, or an object which responds to
    gets method which behaves same as IO#gets does.


=== XMLScan::XMLParser

The non-validating XML parser.

The conformance of XMLScan::XMLParser to the specification
is described in another document.


==== SuperClass:

* ((<XMLScan::XMLScanner>))

==== Class Methods:

--- XMLScan::XMLParser.new(visitor[, option ...])

    XMLScan::XMLParser makes sure the following for each
    method of ((|visitor|)):

    : ((<XMLScan::Visitor#on_stag>))

        After calling this method, XMLScan::Parser always call
        corresponding ((<XMLScan::Visitor#on_etag>)) method.

    In addition, if you never intend error recovery, method calls
    which must not be occurred in a well-formed XML document are
    all suppressed.


=== XMLScan::HTMLScanner

An HTML parser based on ((<XMLScan::XMLScanner>)).

The conformance of XMLScan::HTMLScanner to the specification
is described in another document.

==== SuperClass:

* ((<XMLScan::XMLScanner>))

==== Class Methods:

--- XMLScan::HTMLScanner.new(visitor[, option ...])

    XMLScan::HTMLScanner makes sure the following for each
    method of ((|visitor|)):

    : ((<XMLScan::Visitor#on_xmldecl>))
    : ((<XMLScan::Visitor#on_xmldecl_version>))
    : ((<XMLScan::Visitor#on_xmldecl_encoding>))
    : ((<XMLScan::Visitor#on_xmldecl_standalone>))
    : ((<XMLScan::Visitor#on_xmldecl_end>))

        An XML declaration never appears in an HTML document,
        so XMLScan::HTMLScanner never calls these methods.

    : ((<XMLScan::Visitor#on_stag_end_empty>))

        An empty element tag never appears in an HTML document,
        so XMLScan::HTMLScanner never calls this method.
        An empty element tag causes a parse error.

    : ((<XMLScan::Visitor#wellformed_error>))

        There is no well-formedness constraint for HTML,
        so XMLScan::HTMLScanner never calls this method.

=end
