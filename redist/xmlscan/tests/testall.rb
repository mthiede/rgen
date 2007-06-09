#
# tests/testall.rb
#
# $Id: testall.rb,v 1.6 2003/01/12 04:10:59 katsu Exp $
#

require 'testscanner'
require 'testhtmlscan'
require 'testparser'
require 'testnamespace'
require 'testxmlchar'
require 'testencoding'

load "#{File.dirname($0)}/runtest.rb" if __FILE__ == $0
