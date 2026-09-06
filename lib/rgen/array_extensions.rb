# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/metamodel_builder'

class Array

  def >>(method)
    compact.inject([]) { |r,e| r | ( (o=e.send(method)).is_a?(Array) ? o : [o] ) }
  end

  unless self.public_instance_methods.include?(:method_missing)
    def _th(m)
      # use an array to build the result to achieve similar ordering
      result = []
      inResult = {}
      self.each do |e|
        next if e.nil?
        if e.is_a? RGen::MetamodelBuilder::MMBase
          ((o=e.send(m)).is_a?(Array) ? o : [o] ).each do |v|
            next if v.nil? || inResult[v.object_id]
            inResult[v.object_id] = true
            result << v
          end
        else
          raise StandardError.new("Trying to call a method on an array element not a RGen MMBase")
        end
      end
      result
    end

    def method_missing(m, *args)

      # This extensions has the side effect that it allows to call any method on any
      # empty array with an empty array as the result. This behavior is required for
      # navigating models.
      #
      # This is a problem for Hash[] called with an (empty) array of tupels.
      # It will call to_hash expecting a Hash as the result. When it gets an array instead,
      # it fails with an exception. Make sure it gets a NoMethodException as without this
      # extension and it will catch that and return an empty hash as expected.
      #
      # Similar problems exist for other Ruby built-in methods which are expected to fail.
      #
    return super unless (size == 0 &&
      m != :to_hash && m != :to_str) ||
      self.any?{|e| e.is_a? RGen::MetamodelBuilder::MMBase}
    self._th(m)
    end
  end
end
