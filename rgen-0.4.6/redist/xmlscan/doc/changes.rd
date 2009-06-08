=begin
# $Id: changes.rd,v 1.3 2003/01/22 17:02:25 katsu Exp $

= Changes of xmlscan

== 0.3 series

=== 0.3.0

  * The head of development.


== 0.2 series

=== 0.2.1 - Jan 23, 2003

  * Independented from $KCODE. XMLScanner#kcode and XMLScanner#kcode= were
    added.

  * XMLScan::XMLParser doesn't replace any entity references.
    XMLScan::XMLParser::PredefinedEntity was removed.

  * XMLScan::XMLParser doesn't exchange any method calls. The following
    methods were never called in xmlscan-0.1, but are called in xmlscan-0.2.
      * XMLScan::Visitor#on_charref_hex
      * XMLScan::Visitor#on_attr_charref_hex
      * XMLScan::Visitor#on_stag_end_empty

  * XMLScan::XMLChar now uses regular expressions to search illegal
    characters in an XML document. The parsing speed of XMLScan::XMLParser
    with :strict_char option was dramatically improved.

  * Fixed a few bugs in XMLScan::XMLScanner.

  * Improved parsing speed.

  * Ready for Ruby-1.8.


== 0.1 series

=== 0.1.3 - Jan 10, 2003

    * Added install.rb, which is an simple installer.
    * Fixed a couple of bugs.
    * Improved parsing speed.
    * Rewrote sample benchmark script.

=== 0.1.2 - Dec 20, 2002

    * Fixed several bugs in XMLScan::XMLScanner.
    * XMLScan::Visitor was moved from scanner.rb to visitor.rb.
    * XMLScan::Version was renamed to XMLScan::VERSION.
    * Added new constant XMLScan::RELEASE_DATE.

=== 0.1.1 - Oct 10, 2002

    * The first stable version of xmlscan.

=== 0.1.0rc2 - Sep 30, 2002

    * Another release candidate.

=== 0.1.0rc1 - Sep 28, 2002

    * An release candidate for the stable release.

=== 0.1.0-20020920 - Sep 20, 2000

    * Restarted the project, and this is the first announced version of
      new xmlscan.


== 0.0 series

All versions before 0.1.0-20020920 are called as ``ancient xmlscan'',
since they are so old that even the author have forgotten what they are ;p


=end
