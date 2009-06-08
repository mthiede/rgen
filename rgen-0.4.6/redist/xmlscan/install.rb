#!/usr/bin/ruby
#
# install.rb
#
# $Id: install.rb,v 1.2 2002/12/26 21:09:38 katsu Exp $

require 'rbconfig'
require 'ftools'
require 'find'
require 'getoptlong'

DEFAULT_DESTDIR = Config::CONFIG['sitelibdir'] || Config::CONFIG['sitedir']
SRCDIR = File.dirname(__FILE__)


def install_rb(from, to)
  from = SRCDIR + '/' + from
  Find.find(from) { |src|
    next unless File.file? src
    next unless /\.rb\z/ =~ src
    dst = src.sub(/\A#{Regexp.escape(from)}/, to)
    File.makedirs File.dirname(dst), true
    File.install src, dst, 0644, true
  }
end


destdir = DEFAULT_DESTDIR
begin
  GetoptLong.new([ "-d", "--destdir", GetoptLong::REQUIRED_ARGUMENT ]
                ).each_option { |opt, arg|
    case opt
    when '-d' then
      destdir = arg
    end
  }
rescue
  exit 2
end

install_rb "lib", destdir
