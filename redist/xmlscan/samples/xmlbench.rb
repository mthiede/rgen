#!/usr/bin/ruby
#
# samples/xmlbench.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: xmlbench.rb,v 1.6 2003/03/16 02:34:53 katsu Exp $
#

require 'samples/xmlbench/xmlbench-lib'
require 'benchmark'

$KCODE = 'U'


source = ARGV.shift

unless source then
  STDERR.print "#$0: no source document is given.\n"
  exit 1
end

#XMLBench.weight_limit = 1000
if ARGV.empty? then
  subjects = XMLBench.setup_all
else
  subjects = XMLBench.setup(*ARGV)
end



class BenchmarkRunner

  def initialize(source)
    @source = source
    @bench = []
  end

  def add_bench(*subjects)
    @bench.concat subjects
  end

  BenchTitles = [
    [ '** File **',   proc { |f| f }, ],
    [ '** Array **',  proc { |f| f.readlines } ],
    [ '** String **', proc { |f| f.read } ],
  ]

  def run
    file = File.open(@source)
    source = nil
    pid = nil
    begin
      Benchmark.bm(30) { |x|
        BenchTitles.each { |title,sourcemaker|
          puts title
          @bench.each { |i|
            file.rewind
            pid = fork {
              begin
                source = sourcemaker.call(file)
                GC.start
                x.report(i.name, '') { i.parse source }
              rescue Exception => e
                puts "  #{e.class.name}"
              ensure
                file.close
              end
            }
            Process.waitpid(pid)
            pid = nil
            puts "  killed at status #{$?}" unless $? == 0
          }
        }
      }
    ensure
      Process.waitpid pid if pid rescue nil
      file.close
    end
    self
  end

end


bench = BenchmarkRunner.new(source)
bench.add_bench(*subjects)
bench.run
