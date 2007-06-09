#
# tests/deftestcase.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: deftestcase.rb,v 1.7 2003/02/28 12:31:07 katsu Exp $
#

module DefTestCase

  class << self
    private
    def append_features(mod)
      super
      mod.extend DefTestCaseSingleton
    end
  end


  module DefTestCaseSingleton

    private

    def deftestcase(prefix, testcases)
      filename, lineno = caller.first.split(':')
      lineno = lineno.to_i + 1
      testno = 0
      testcases.split(/^\s+?^/).each { |test|
        test = test.split(/^/)
        test.each { |i| i.strip! }
        args = test.reject { |i| i.empty? or /\A#/ =~ i }
        unless args.empty? then
          name = sprintf('test_%s_%03d', prefix, testno += 1)
          src = "def #{name} ; do_testcase(#{args.join(',')}) ; end"
          module_eval src, filename, lineno
        end
        lineno += test.size + 1
      }
    end

  end


  private

  def do_testcase(src, *expected)
    expected = [ [:on_start_document] ] + expected + [ [:on_end_document] ]
    result = parse(src)
    begin
      assert_equal expected, result
    rescue Test::Unit::AssertionFailedError => e
      was = ''
      result.each_with_index { |i,n|
        was << "\t#{i.inspect}"
        was << " <= !!!!" unless i == expected[n]
        was << "\n"
      }
      msg = "\ntestcase:\n\t" + src +
            "\nexpected:\n" + expected.collect{|i|"\t#{i.inspect}\n"}.join +
            "but was:\n" + was
      backtrace = e.backtrace.reject { |i|
        /\A#{__FILE__}:\d+:in `do_testcase'/n =~ i
      }
      raise e, msg, backtrace
    end
  end


  def parse(src)
    raise NotImplementedError, "abstract method"
  end

end
