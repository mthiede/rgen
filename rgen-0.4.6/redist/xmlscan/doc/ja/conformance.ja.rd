=begin
# $Id: conformance.rd.src,v 1.1 2003/01/22 16:41:45 katsu Exp $

= xmlscan の規格への適合性

この文書では、xmlscan に含まれる各パーサの XML 関連規格への
適合性について述べます。

== 概要

xmlscan は XML 1.0 Sepcification ((<[XML]>)) でいうところの
「妥当性を検証しないプロセサ」です。妥当性を検証しないプロセサに
求められる条件のほとんどを満たしていますが、実装の都合上、主に
次のような制約があります。詳細は各クラス毎の記述を参照してください。

 * UTF-16 で書かれたXML文書を直接解析できません。
 * デフォルトでは、XML文書中で、又はある文脈で使用が認められない
   文字が含まれていないことを検査しません。
 * あらゆる外部実体を読み込みません。外部解析対象実体に関する
   整形式制約はチェックされません。
 * 内部DTDサブセットは読み飛ばします (将来のバージョンでサポート予定)。
   DTDに関する整形式制約はチェックされません。


== XMLScan::XMLScanner の規格への適合性

XMLScan::XMLScanner はXML文書を解析し、XML宣言、文書型宣言、処理命令、
コメント、開始タグ、終了タグ、空要素タグ、CDATAセクション、一般実体参照、
および文字参照の認知のみを行います。以下に述べる場合を除いて、
これらが現れてはならない文脈で現れたとしても、エラーになりません。

XML宣言、文書型宣言 (内部DTDサブセットを除く)、処理命令、コメント、
開始タグ、終了タグ、空要素タグ、CDATAセクション、一般実体参照、および
文字参照が XML 1.0 Specification ((<[XML]>)) に定める生成規則に
マッチしない場合、解析エラーとなります。

実用的な処理速度を得るため、strict_char オプションが指定されていない
場合、名前や文字データ等に使用が認められない文字が含まれていないことを
検査しません。その文脈で区切り子として認識されるべき文字を除いた全ての
文字が容認されます。具体的には、strict_char オプションが指定されて
いなければ、生成規則 Char[2], Name[5], Nmtoken[7], EntityValue[9],
AttValue[10], SystemLiteral[11], PubidChar[13], CharData[14],
VersionNum[26], EncName[81] は厳密にチェックされません。

行末の正規化を行いません。

Ruby 自体がサポートしていないため、UTF-16 で書かれた文書を
直接解析することはできません。解析前に一旦 UTF-8 に変換する
必要があります。

文書の先頭以外で `<?xml' が現れた場合は、それを処理命令とみなします。

スタンドアロン文書宣言が yes または no であるかをチェックしません。

処理命令のターゲットが xml でないことをチェックしません。

文書型宣言が前書き以外に現れた場合、また2回以上現れた場合は
解析エラーとなります。

属性値の中に `<' の文字が直接現れた場合、整形式制約違反エラーと
なります。strict_char オプションが指定されている場合、整形式制約
"Legal Character" をチェックします。これ以外の整形式制約はまったく
チェックされません。

内部DTDサブセットは読み飛ばします。


== XMLScan::XMLParser の規格への適合性

XMLScan::XMLParser は、妥当性を検証しないXMLプロセサとして求められる
条件のほとんど全てを満たすことを目標にしています。

XMLScan::XMLScanner の strict_char オプションに関する記述、及び
UTF-16 に関する記述は、そのまま XMLScan::XMLParser にも当てはまります。
文字参照に関する以下の制約は、strict_char オプションが指定された
場合のみチェックされます。

 * Well-formedness constraint: Legal Character

行末の正規化を行いません。

内部DTDサブセットは読み飛ばします。内部DTDサブセットに関する以下の
整形式制約はチェックされません。

 * Well-formedness constraint: PEs in Internal Subset
 * Well-formedness constraint: PE Between Declarations
 * Well-formedness constraint: No External Entity References
 * Well-formedness constraint: Entity Declared
 * Well-formedness constraint: Parsed Entity
 * Well-formedness constraint: No Recursion
 * Well-formedness constraint: In DTD

定義済み実体 (lt,gt,amp,quot,apos) を除く全ての一般実体参照は、
宣言が読み込まれていない実体への参照として報告されます。

外部DTDサブセットは取り込みません。外部DTDサブセットに関する以下の
整形式制約はチェックされません。

 * Well-formedness constraint: External Subset

宣言を読み込んでいない実体の置換テキストに < が含まれていることを
確認できないため、以下の整形式制約はチェックされません。

 * Well-formedness constraint: No < in Attribute Values


== XMLScan::XMLNamespace の規格への適合性

XMLScan::XMLNamespace は Namespaces in XML 及びその errata ((<[Namespaces]>))
に定められる全ての制約をチェックし、 XML 文書が名前空間整形式
(namespace-well-formed) であることを確認します。

XMLScan::XMLParser に起因する制限は、そのまま XMLScan::XMLNamespace
にも継承されます。


== 参考文献

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
    重要な訂正が ((<URL:http://www.w3.org/XML/xml-names-19990114-errata>))
    に含まれている.


=end
