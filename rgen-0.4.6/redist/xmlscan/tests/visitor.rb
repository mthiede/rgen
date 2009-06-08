#
# tests/visitor.rb
#
#   Copyright (C) UENO Katsuhiro 2002
#
# $Id: visitor.rb,v 1.3 2002/09/24 21:39:30 katsu Exp $
#

module RecordingVisitor

  def initialize
    @result = []
  end

  attr_reader :result

  def self.new_class(visitor)
    klass = Class.new
    mod = self
    klass.module_eval { include mod, visitor }
    methods = visitor.instance_methods
    visitor.included_modules.each { |i| methods.concat i.instance_methods }
    methods.sort.uniq.each { |i|
      klass.module_eval <<-END, __FILE__, __LINE__ + 1
        def #{i}(*args)
          @result.push [ :#{i} ].concat(args)
        end
      END
    }
    klass
  end


end
