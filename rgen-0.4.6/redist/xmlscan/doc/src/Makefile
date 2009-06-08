# Makefile
# $Id: Makefile,v 1.1 2003/01/22 16:42:12 katsu Exp $

RUBY = ruby
RD2  = rd2
LANGSPLIT = $(RUBY) src/langsplit.rb

SOURCES = src/manual.rd.src src/conformance.rd.src

TARGETS_en = $(SOURCES:.rd.src=.rd) $(SOURCES:.rd.src=.html)
TARGETS_ja = $(SOURCES:.rd.src=.ja.rd) $(SOURCES:.rd.src=.ja.html)

TARGETS = $(subst src/,en/,$(TARGETS_en)) \
          $(subst src/,ja/,$(TARGETS_ja)) \
          changes.html

all: $(TARGETS)

clean:
	-rm -f $(TARGETS)

.SUFFIXES: .html .rd

.rd.html:
	$(RD2) $< > $@

en/manual.rd: src/manual.rd.src
	$(LANGSPLIT) -en $< > $@
ja/manual.ja.rd: src/manual.rd.src
	$(LANGSPLIT) -ja $< > $@
en/conformance.rd: src/conformance.rd.src
	$(LANGSPLIT) -en $< > $@
ja/conformance.ja.rd: src/conformance.rd.src
	$(LANGSPLIT) -ja $< > $@

en/manual.html: en/manual.rd
ja/manual.ja.html: ja/manual.ja.rd
en/conformance.html: en/conformance.rd
ja/conformance.ja.html: ja/conformance.ja.rd

changes.html: changes.rd
