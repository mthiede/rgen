#!/usr/bin/ruby
#
# samples/xmlconftest.rb - OASIS XML Conformance Test
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlconftest.rb,v 1.3 2003/01/22 16:46:32 katsu Exp $
#
#
# OASIS - Technical Committees - XML Conformance
#    http://www.oasis-open.org/committees/xml-conformance/xml-test-suite.shtml
#

require 'samples/xmlbench/xmlbench-lib'

$KCODE = 'U'

# you must edit here as your environment.
XMLCONFDIR = "./xmlconf/"
XMLCONFLOG = "./xmlconftest.log"



PositiveTests = Dir.glob(XMLCONFDIR + '*/valid/*/*.xml') +
                Dir.glob(XMLCONFDIR + 'oasis/p*pass*.xml')

NegativeTests = Dir.glob(XMLCONFDIR + '*/not-wf/*/*.xml') +
                Dir.glob(XMLCONFDIR + 'oasis/p*fail*.xml')

NegativeTestRejects = [
  # non-validating processors may accept these instances.
  'oasis/p06fail1.xml',
  'oasis/p08fail1.xml',
  'oasis/p08fail2.xml',
  # non-validating processors may accept these instances
  # since they require XML processors to read external entites.
  'ibm/not-wf/P30/ibm30n01.xml',
  'ibm/not-wf/P31/ibm31n01.xml',
  'ibm/not-wf/P61/ibm61n01.xml',
  'ibm/not-wf/P62/ibm62n01.xml',
  'ibm/not-wf/P62/ibm62n02.xml',
  'ibm/not-wf/P62/ibm62n03.xml',
  'ibm/not-wf/P62/ibm62n04.xml',
  'ibm/not-wf/P62/ibm62n05.xml',
  'ibm/not-wf/P62/ibm62n06.xml',
  'ibm/not-wf/P62/ibm62n07.xml',
  'ibm/not-wf/P62/ibm62n08.xml',
  'ibm/not-wf/P63/ibm63n01.xml',
  'ibm/not-wf/P63/ibm63n02.xml',
  'ibm/not-wf/P63/ibm63n03.xml',
  'ibm/not-wf/P63/ibm63n04.xml',
  'ibm/not-wf/P63/ibm63n05.xml',
  'ibm/not-wf/P63/ibm63n06.xml',
  'ibm/not-wf/P63/ibm63n07.xml',
  'ibm/not-wf/P64/ibm64n01.xml',
  'ibm/not-wf/P64/ibm64n02.xml',
  'ibm/not-wf/P64/ibm64n03.xml',
  'ibm/not-wf/P65/ibm65n01.xml',
  'ibm/not-wf/P65/ibm65n02.xml',
  'ibm/not-wf/P77/ibm77n03.xml',
  'ibm/not-wf/P77/ibm77n04.xml',
  'ibm/not-wf/P78/ibm78n01.xml',
  'ibm/not-wf/P78/ibm78n02.xml',
  'ibm/not-wf/P79/ibm79n01.xml',
  'ibm/not-wf/P79/ibm79n02.xml',
  'oasis/p09fail1.xml',
  'oasis/p09fail2.xml',
  'oasis/p30fail1.xml',
  'oasis/p31fail1.xml',
  'oasis/p61fail1.xml',
  'oasis/p62fail1.xml',
  'oasis/p62fail2.xml',
  'oasis/p63fail1.xml',
  'oasis/p63fail2.xml',
  'oasis/p64fail1.xml',
  'oasis/p64fail2.xml',
  'xmltest/not-wf/ext-sa/001.xml',
  'xmltest/not-wf/ext-sa/002.xml',
  'xmltest/not-wf/ext-sa/003.xml',
  'xmltest/not-wf/not-sa/001.xml',
  'xmltest/not-wf/not-sa/003.xml',
  'xmltest/not-wf/not-sa/004.xml',
  'xmltest/not-wf/not-sa/005.xml',
  'xmltest/not-wf/not-sa/006.xml',
  'xmltest/not-wf/not-sa/007.xml',
  'xmltest/not-wf/not-sa/008.xml',
]

#NegativeTests.reject! { |i|
#  NegativeTestRejects.include? i[XMLCONFDIR.size..-1]
#}



class XMLConfTest

  def initialize(parser)
    @parser = parser
    @result = {}
  end

  def class_name
    @parser.class.name
  end

  def name
    @parser.name
  end

  def total
    @result.size
  end

  def success
    @result.select{ |k,v| v }.collect{ |k,v| k }.sort
  end

  def failure
    @result.select{ |k,v| not v }.collect{ |k,v| k }.sort
  end

  def success_percent
    100.0 * success.size / total
  end

  def failure_percent
    100.0 * failure.size / total
  end

  def check(format, *files)
    total = 0
    ok = 0
    failed = 0
    files.each { |i|
      total += 1
      File.open(i) { |f|
        result = true
        begin
          @parser.parse f.read
        rescue Exception
          result = false
        end
        @result[i] = result
        if result then
          ok += 1
        else
          failed += 1
        end
      }
      printf format+"\r",
             name, total, ok, ok*100.0/total, failed, failed*100.0/total
    }
    print "\n"
  end

end



XMLBench.weight_limit = 10

if ARGV.empty? then
  subjects = XMLBench.setup_all
else
  subjects = XMLBench.setup(*ARGV)
end



log = File.open(XMLCONFLOG, 'w')
END { log.close }


puts ' '*30+'  total     success           failure'

puts "** POSITIVE TEST **"

subjects.each { |parser|
  conf = XMLConfTest.new(parser)
  conf.check("%-30s   %4d        %4d (%5.1f%%)     %4d (%5.1f%%)",
             *PositiveTests)
  if conf.failure.size > 0 then
    log.puts "---- #{conf.name} couldn't parse the following files:"
    conf.failure.each { |i| log.puts "P #{conf.class_name} #{i}" }
    log.puts
  end
}

puts "** NEGATIVE TEST **"

subjects.each { |parser|
  conf = XMLConfTest.new(parser)
  conf.check("%-30s   %4d        %4d (%5.1f%%)     %4d (%5.1f%%)",
             *NegativeTests)
  if conf.success.size > 0 then
    log.puts "---- #{conf.name} could parse the following files:"
    conf.success.each { |i| log.puts "N #{conf.class_name} #{i}" }
    log.puts
  end
}
