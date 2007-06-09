=begin
# $Id: conformance.rd.src,v 1.1 2003/01/22 16:41:45 katsu Exp $

= Conformance of xmlscan to the specifications

This document describes the conformance of each parser
included in xmlscan for XML related specifications.

== Abstract

XMLscan is one of "non-validating XML processor" according to
XML 1.0 Specification ((<[XML]>)). XMLscan is satisfied with
almost conditions required for a non-validation XML processor,
though, for the limitations of implementations, there are mainly
the following restrictions. For detail, See the below
descriptions for each class.

 * It is impossible to parse an XML document encoded in UTF-16
   directly.
 * By default, it is not checked for illegal characters which
   must not appear in an XML document or in a context.
 * XMLscan doesn't read any external entities. Well-formedness
   constraints for external entities are not checked.
 * XMLscan skips an internal DTD subset. (it will be supported
   in future version). Well-formedness constraints for an
   internal DTD subset are not checked.


== Conformance of XMLScan::XMLScanner

XMLScan::XMLScanner tokenize an XML document and only recognize
each XML declaration, document type declaration, processing
instruction, comment, start tag, end tag, empty element tag,
CDATA section, general entity reference, and character reference.
It is NOT an error even that one of these parts appears in the
context which prohibits existence of it, except in the case
described below.

It is reported as an parse error that an XML declaration,
document type definition (except internal DTD subset),
processing instruction, comment, start tag, end tag, empty
element tag, CDATA section, general entity reference, or a
character reference is not matched with its production defined
in XML 1.0 Specification ((<[XML]>)).

For reasonably speed, if `strict_char' option is not specified,
XMLScan::XMLScanner doesn't check whether a name or character
data includes an illegal characters for it. All characters
except ones recognized as one of delimiters in that context
are allowed. To be more precise, without `strict_char' option,
the production Char[2], Name[5], Nmtoken[7], EntityValue[9],
AttValue[10], SystemLiteral[11], PubidChar[13], CharData[14],
VersionNum[26], and EncName[81] are not checked strictly.

XMLScan::XMLScanner doesn't normalize linebreaks.

Since Ruby is not supported UTF-16, it is impossible to parse
an XML document encoded in UTF-16 as it is. You need to convert
it to UTF-8 before parsing.

`<?xml' in a place except the beginning of an XML document is
regarded as a processing instruction.

It is not checked whether the value of a standalone document
documentation is either "yes" or "no".

It is not checked whether a target in a processing instruction
is not "xml" or like, which is a reserved target.

It is reported as a parse error in the case that a document type
declaration appears in a place except prolog, or two or more
document type declarations are found in one document.

It is reported as a well-formedness constraint violation
that `<' appears directly in a attribute value. If strict_char
option is specified, XMLScan::XMLScanner checks
well-formedness constraint: Legal Character.
Any other well-formedness constraints are not checked.

XMLScan::XMLScanner skips an internal DTD subset.


== Conformance of XMLScan::XMLParser

The goal of XMLScan::XMLParser is to satisfy almost all
conditions required to a non-validating XML parser.

The description for XMLScan::XMLScanner about `strict_char'
option and the description for UTF-16 are applicable to
XMLScan::XMLParser. The following well-formedness constraints
about a character reference are checked only if `strict_char'
option is specified;

 * Well-formedness constraint: Legal Character

XMLScan::XMLScanner doesn't normalize linebreaks.

XMLScan::XMLParser skips an internal DTD subset. The following
well-formedness constraints about an internal DTD subset are
not checked;

 * Well-formedness constraint: PEs in Internal Subset
 * Well-formedness constraint: PE Between Declarations
 * Well-formedness constraint: No External Entity References
 * Well-formedness constraint: Entity Declared
 * Well-formedness constraint: Parsed Entity
 * Well-formedness constraint: No Recursion
 * Well-formedness constraint: In DTD

All general entity references except ones to predefined entities
(lt,gt,amp,quot,apos) are reported as ones to undeclared entities.

External DTD subsets are not read. The following well-formedness
constraints about an external DTD subset are not checked;

 * Well-formedness constraint: External Subset

Since XMLScan::XMLParser cannot check whether a replacement text
of an undeclared entity includes `<', the following
well-formedness constraints are not checked completely;

 * Well-formedness constraint: No < in Attribute Values


== Conformance of XMLScan::XMLNamespace

XMLScan::XMLNamespace checks for all constraints specified in
``Namespaces in XML'' and its errata ((<[Namespaces]>)), and
ensure that an XML document is namespace-well-formed.

All limitations for XMLScan::XMLParser are inherited to
XMLScan::XMLNamespace.


== References

: [XML]
    W3C (World Wide Web Consortium).
    Extensible Markup Language (XML) 1.0 (Second Edition),
    January 2000.
    ((<URL:http://www.w3.org/TR/2000/REC-xml-20001006>))

: [Namespaces]
    W3C (World Wide Web Consortium).
    Namespaces in XML,
    January 1999.
    ((<URL:http://www.w3.org/TR/1999/REC-xml-names-19990114>)).
    Important corrections are found at
    ((<URL:http://www.w3.org/XML/xml-names-19990114-errata>)).


=end
