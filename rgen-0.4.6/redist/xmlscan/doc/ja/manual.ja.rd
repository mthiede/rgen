=begin
# $Id: manual.rd.src,v 1.1 2003/01/22 16:41:45 katsu Exp $

= xmlscan version 0.2 リファレンスマニュアル

== 概要

xmlscan は Ruby だけで書かれた non-validating XML parser です。

次のような特長があります。

: 100% pure Ruby
    拡張ライブラリを一切必要としないので、1.6 以上の Ruby インタプリタだけ
    あれば完全に動作します。(標準添付の拡張ライブラリも必要としません。)

: 規格への適合性
    xmlscan は、XML 1.0 Specification で述べられている、妥当性を検証しない
    プロセサに求められる全ての条件を満たすことを目標に開発が進められて
    います。

: 高速
    xmlscan の解析の速さは、おそらく、現存する Ruby で書かれた
    XML/HTML parser の中で最速です。

: 様々なCESに対応
    xmlscan は少なくとも iso-8859-*, EUC-*, Shift_JIS, UTF-8 で書かれた
    XML文書をそのまま解析できます。ただし UTF-16 は扱えません。

: 解析するだけ
    xmlscan の役割は、ただXML文書を解析することだけです。XML文書を
    簡便に取り扱うための高レベルな機能は提供しません。xmlscan は
    そのような機能を提供するライブラリのコア部分として使われることを
    想定しています。

: HTML
    オマケで HTML を構文解析する htmlscan が付いています。


== 文字エンコーディングについて

デフォルトでは、xmlscan がどの CES (Character Encoding Scheme) で
XML文書を解析するかはグローバル変数 $KCODE の値によって決まります。
EUC-*, Shift_JIS, UTF-8 で書かれたXML文書を解析するには $KCODE や
((<XMLScan::XMLScanner#kcode=>)) に適切な値を設定する必要があります。

UTF-16 は直接サポートしていません。解析前に一旦 UTF-8 に変換する
必要があります。


== XML名前空間について

XML名前空間は xmlscan/namespace.rb で実装されていますが、インターフェースを
大きく変更する予定があるため undocumented とします。



== クラスリファレンス


=== XMLScan::Error

xmlscan に関する全ての例外のスーパークラス。

これらの例外は、XMLScan::Visitor のインスタンスが、XMLScan::XMLScanner や
XMLScan::XMLParser からエラー報告を受け取ったときに、デフォルトで発生させる
ものです。各パーサが直接これらの例外を投げることはありません。

#次の例外は xmlscan/scanner.rb で定義されています。

: XMLScan::ParseError

    生成規則にマッチしない等、制約違反以外のエラー。

: XMLScan::NotWellFormedError

    整形式制約に違反している。

: XMLScan::NotValidError

    妥当性制約に違反している。


=== XMLScan::Visitor

XML文書の解析結果を受け取るための Mix-in です。

xmlscan に含まれる各 parser は、文書の先頭から構文解析を行い、タグ等の
構文要素を見つけるたびに、パーサに与えられた XMLScan::Visitor の
インスタンスの特定のメソッドを呼び出します。この呼び出しは、必ず文書の
先頭から順番に行われます。

==== メソッド:

特に記述の無い限り、各メソッドはデフォルトでは何もしません。

--- XMLScan::Visitor#parse_error(msg)

    生成規則にマッチしない等、制約違反以外のエラーを発見した場合に
    呼び出されます。デフォルトでは ((<XMLScan::ParseError>))例外を
    発生させます。例外処理等の大域脱出を行わずに普通に制御を
    パーサに返すと、パーサはエラーを回復して解析を続けます。

--- XMLScan::Visitor#wellformed_error(msg)

    整形式制約違反を発見した場合に呼び出されます。デフォルトでは
    ((<XMLScan::NotWellFormedError>))例外を発生させます。例外処理等の
    大域脱出を行わずに普通に制御をパーサに返すと、パーサはエラーを
    回復して解析を続けます。

--- XMLScan::Visitor#valid_error(msg)

    妥当性制約違反を発見した場合に呼び出されます。デフォルトでは
    ((<XMLScan::NotValidError>))例外を発生させます。例外処理等の
    大域脱出を行わずに普通に制御をパーサに返すと、パーサはエラーを
    回復して解析を続けます。

    なお、現在の xmlscan には妥当性を検証するXMLプロセサは
    含まれていません。このメソッドは将来の版のために予約されています。

--- XMLScan::Visitor#warning(msg)

    エラーではないが推奨されない事柄や、xmlscan では十分に解析できない
    構文を発見した場合に呼び出されます。

--- XMLScan::Visitor#on_start_document

    XML文書の解析を始める直前に呼び出されます。このメソッドが呼び出された
    後には必ず、対応する ((<XMLScan::Visitor#on_end_document>)) メソッドが
    呼び出されます。

--- XMLScan::Visitor#on_end_document

    XML文書の終端まで解析し終った後に呼び出されます。

--- XMLScan::Visitor#on_xmldecl
--- XMLScan::Visitor#on_xmldecl_version(str)
--- XMLScan::Visitor#on_xmldecl_encoding(str)
--- XMLScan::Visitor#on_xmldecl_standalone(str)
--- XMLScan::Visitor#on_xmldecl_other(name, value)
--- XMLScan::Visitor#on_xmldecl_end

    XML宣言を発見した場合に呼び出されます。

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

    XML宣言を発見した場合、on_xmldecl と on_xmldecl_end は必ず
    呼び出されます。他のメソッドは対応する構文がXML宣言中に
    現れなかった場合は呼び出されません。

    on_xmldecl_other は version, encoding, standalone 以外の宣言が
    XML宣言の中にあった場合に呼び出されます。そのような宣言は構文上
    許されていないため、on_xmldecl_other が呼び出される前には必ず
    ((<XMLScan::Visitor#parse_error>)) メソッドが呼び出されることに
    注意して下さい。

--- XMLScan::Visitor#on_doctype(root, pubid, sysid)

    文書型宣言を発見した場合に呼び出されます。

             document                            argument
        --------------------------------------------------------------
         1: <!DOCTYPE foo>                      ('foo', nil,   nil)
         2: <!DOCTYPE foo SYSTEM "bar">         ('foo', nil,   'bar')
         3: <!DOCTYPE foo PUBLIC "bar">         ('foo', 'bar',  nil )
         4: <!DOCTYPE foo PUBLIC "bar" "baz">   ('foo', 'bar', 'baz')

--- XMLScan::Visitor#on_prolog_space(str)

    前書きの中に空白を発見した場合に呼び出されます。

--- XMLScan::Visitor#on_comment(str)

    コメントを発見した場合に呼び出されます。

--- XMLScan::Visitor#on_pi(target, pi)

    処理命令を発見した場合に呼び出されます。

--- XMLScan::Visitor#on_chardata(str)

    文字データを発見した場合に呼び出されます。

--- XMLScan::Visitor#on_cdata(str)

    CDATAセクションを発見した場合に呼び出されます。

--- XMLScan::Visitor#on_entityref(ref)

    属性値の中以外の場所で一般実体参照を発見した場合に呼び出されます。

--- XMLScan::Visitor#on_charref(code)
--- XMLScan::Visitor#on_charref_hex(code)

    属性値の中以外の場所で文字参照を発見した場合に呼び出されます。
    文字コードが10進数で指定されていた場合は on_charref、16進数で
    指定されていた場合は on_charref_hex が呼び出されます。
    ((|code|))は整数です。

--- XMLScan::Visitor#on_stag(name)
--- XMLScan::Visitor#on_attribute(name)
--- XMLScan::Visitor#on_attr_value(str)
--- XMLScan::Visitor#on_attr_entityref(ref)
--- XMLScan::Visitor#on_attr_charref(code)
--- XMLScan::Visitor#on_attr_charref_hex(code)
--- XMLScan::Visitor#on_attribute_end(name)
--- XMLScan::Visitor#on_stag_end_empty(name)
--- XMLScan::Visitor#on_stag_end(name)

    開始タグを発見した場合に呼び出されます。

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

    開始タグを発見した場合、on_stag と、対応する on_stag_end 又は
    on_stag_end_empty は必ず呼び出されます。他のメソッドは、開始タグの
    中に属性が現れなかった場合は呼び出されません。

    属性を発見した場合、on_attribute と on_attribute_end は必ず
    呼び出されます。属性値が空 (fuga="") の時は、この2つのメソッドのみが
    呼び出されます。

    on_attr_entityref は属性値の中で一般実体参照を発見した場合に
    呼び出されます。on_charref 及び on_charref_hex は属性値の中で
    文字参照を発見した場合に呼び出されます。

    タグが空要素タグだった場合は、on_stag_end メソッドの代わりに
    on_stag_end_empty メソッドが呼び出されます。

--- XMLScan::Visitor#on_etag(name)

    終了タグを発見した場合に呼び出されます。



=== XMLScan::XMLScanner

XML文書を字句解析し、タグ等を認識するスキャナです。

XMLScan::XMLScanner の規格適合性については、他の文書で述べています。

==== スーパークラス:

* Object

==== クラスメソッド:

--- XMLScan::XMLScanner.new(visitor[, option ...])

    XMLScan::XMLScanner オブジェクトを生成します。((|visitor|))は
    XMLScan::Visitor のインスタンスで、XMLScan::XMLScanner オブジェクトから
    解析結果を受け取ります。

    ((|option|))は文字列又はシンボルで指定します。optionには
    次のものがあります。

    : 'strict_char'

        (({require 'xmlscan/xmlchar'})) すると指定できるようになります。
        不正な文字が使われていないかどうかのチェックを行います。
        パフォーマンスが著しく低下します。

==== メソッド:

--- XMLScan::XMLScanner#kcode= arg

    CESを指定します。((|arg|))の解釈は、nil を除いて $KCODE と同じです。
    ((|arg|))が nil のときは、どの CES で解析を行うかは $KCODE の値によって
    決まります。

--- XMLScan::XMLScanner#kcode

    どの CES で解析を行うかを Regexp#kcode と同じ形式で返します。
    nilのときは$KCODEに依存することを表します。

--- XMLScan::XMLScanner#parse(source)

    ((|source|)) をXML文書として解析します。((|source|)) は文字列か
    文字列の配列、又は IO#gets と同じ振る舞いをする gets メソッドを持つ
    オブジェクトでなければなりません。


=== XMLScan::XMLParser

妥当性を検証しない XML parser です。

XMLScan::XMLParser の規格適合性については、他の文書で述べています。


==== スーパークラス:

* ((<XMLScan::XMLScanner>))

==== クラスメソッド:

--- XMLScan::XMLParser.new(visitor[, option ...])

    XMLScan::XMLParser オブジェクトは((|visitor|))の各メソッドについて、
    次のことを保証します。

    : ((<XMLScan::Visitor#on_stag>))

        このメソッドを呼び出した後に、対応する ((<XMLScan::Visitor#on_etag>))
        メソッドを必ず呼び出します。

    加えて、エラー回復を行わなければ、整形式のXML文書では起こり得ない
    メソッド呼び出しは全て抑制されます。


=== XMLScan::HTMLScanner

((<XMLScan::XMLScanner>)) を元にした HTML パーサです。

XMLScan::HTMLScanner の規格適合性については、他の文書で述べています。

==== スーパークラス:

* ((<XMLScan::XMLScanner>))

==== クラスメソッド:

--- XMLScan::HTMLScanner.new(visitor[, option ...])

    XMLScan::HTMLScanner オブジェクトは((|visitor|))の各メソッドについて、
    次のことを保証します。

    : ((<XMLScan::Visitor#on_xmldecl>))
    : ((<XMLScan::Visitor#on_xmldecl_version>))
    : ((<XMLScan::Visitor#on_xmldecl_encoding>))
    : ((<XMLScan::Visitor#on_xmldecl_standalone>))
    : ((<XMLScan::Visitor#on_xmldecl_end>))

        HTML には XML宣言は存在しないので、これらのメソッドを呼び出すことは
        ありません。

    : ((<XMLScan::Visitor#on_stag_end_empty>))

        HTML には空要素タグは存在しないので、このメソッドを呼び出すことは
        ありません。空要素タグは解析エラーになります。

    : ((<XMLScan::Visitor#wellformed_error>))

        HTML には整形式制約が存在しないので、このメソッドを呼び出すことは
        ありません。

=end
