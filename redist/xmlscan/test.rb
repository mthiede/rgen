#!/usr/bin/ruby
$-w = true
$LOAD_PATH.unshift 'lib'
$LOAD_PATH.unshift 'tests'
Dir.chdir File.dirname($0)
require 'testall'
load 'runtest.rb'
