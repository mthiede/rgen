module RGen

module Util

# A PatternMatcher can be used to find, insert and remove patterns on a given model.
#
# A pattern is specified by means of a block passed to the add_pattern method.
# The block must take an Environment as first parameter and at least one model element
# as connection point as further parameter. The pattern matches if it can be found
# in a given environment and connected to the given connection point elements.
#
class PatternMatcher

  Match = Struct.new(:root, :elements, :bound_values)

  def initialize
    @patterns = {} 
    @insert_mode = false
  end

  def add_pattern(name, &block)
    raise "a pattern needs at least 2 block parameters: " + 
      "an RGen environment and a model element as connection point" \
      unless block.arity >= 2
    @patterns[name] = block
  end

  def find_pattern(env, name, *connection_points)
    match = find_pattern_internal(env, name, *connection_points)
  end

  def insert_pattern(env, name, *connection_points)
    @insert_mode = true
    root = evaluate_pattern(name, env, connection_points)
    @insert_mode = false
    root
  end

  def remove_pattern(env, name, *connection_points)
    match = find_pattern_internal(env, name, *connection_points)
    if match
      match.elements.each do |e|
        disconnect_element(e)
        env.delete(e)
      end
      match
    else
      nil
    end
  end

  def lazy(&block)
    if @insert_mode
      block.call
    else
      Lazy.new(&block)
    end
  end

  class Lazy < RGen::MetamodelBuilder::MMGeneric
    def initialize(&block)
      @block = block
    end
    def _eval
      @block.call
    end
  end

  private

  class Proxy < RGen::MetamodelBuilder::MMProxy
    attr_reader :_target
    def initialize(target)
      @_target = target
    end
    def method_missing(m, *args)
      result = @_target.send(m, *args)
      if result.is_a?(Array)
        result.collect do |e|
          if e.is_a?(RGen::MetamodelBuilder::MMBase)
            Proxy.new(e)
          else
            e
          end
        end
      else
        if result.is_a?(RGen::MetamodelBuilder::MMBase)
          Proxy.new(result)
        else
          result 
        end
      end
    end
  end

  class Bindable < RGen::MetamodelBuilder::MMGeneric
    def initialize
      @bound = false
      @value = nil
    end
    def _bound?
      @bound
    end
    def _bind(value)
      @value = value
      @bound = true
    end
    def _value
      @value
    end
    def to_s
      @value.to_s
    end
  end

  def find_pattern_internal(env, name, *connection_points)
    proxied_args = connection_points.collect{|a| Proxy.new(a)}
    temp_env = RGen::Environment.new
    bindables = (1..(num_pattern_variables(name) - connection_points.size)).collect{|i| Bindable.new}
    pattern_root = evaluate_pattern(name, temp_env, proxied_args+bindables)
    candidates = candidates_via_connection_points(pattern_root, connection_points)
    candidates ||= env.find(:class => pattern_root.class)
    candidates.each do |e|
      matched = match(pattern_root, e)
      return Match.new(e, matched, bindables.collect{|b| b._value}) if matched 
    end
    nil
  end

  def candidates_via_connection_points(pattern_root, connection_points)
    @candidates_via_connection_points_refs ||= {}
    refs = (@candidates_via_connection_points_refs[pattern_root.class] ||= 
      pattern_root.class.ecore.eAllReferences.reject{|r| r.derived || r.many || !r.eOpposite})
    candidates = nil 
    refs.each do |r|
      t = pattern_root.getGeneric(r.name)
      cp = t.is_a?(Proxy) && connection_points.find{|cp| cp.object_id == t._target.object_id}
      if cp
        elements = cp.getGenericAsArray(r.eOpposite.name)
        candidates = elements if candidates.nil? || elements.size < candidates.size 
      end
    end
    candidates
  end
  
  def match(pat_element, test_element)
    visited = {}
    check_later = []
    return false unless match_internal(pat_element, test_element, visited, check_later)
    while cl = check_later.shift
      pv, tv = cl.lazy._eval, cl.value
      if cl.feature.is_a?(RGen::ECore::EAttribute)
        unless pv == tv
          match_failed(cl.feature, "wrong attribute value (lazy)")
          return false 
        end
      else
        if pv.is_a?(Proxy)
          unless pv._target.object_id == tv.object_id
            match_failed(f, "wrong target object")
            return false 
          end
        else
          unless match_internal(pv, tv, visited, check_later)
            return false 
          end
        end
      end
    end
    visited.keys
  end

  CheckLater = Struct.new(:feature, :lazy, :value)
  def match_internal(pat_element, test_element, visited, check_later)
    return true if visited[test_element]
    visited[test_element] = true
    unless pat_element.class == test_element.class
      match_failed(nil, "wrong class: #{pat_element.class} vs #{test_element.class}")
      return false 
    end
    all_structural_features(pat_element).each do |f|
      pat_values = pat_element.getGenericAsArray(f.name)
      test_values = test_element.getGenericAsArray(f.name)
      unless pat_values.size == test_values.size
        match_failed(f, "wrong size")
        return false 
      end
      pat_values.each_with_index do |pv,i|
        tv = test_values[i]
        if pv.is_a?(Lazy)
          check_later << CheckLater.new(f, pv, tv)
        elsif pv.is_a?(Bindable)
          if pv._bound?
            unless pv._value == tv
              match_failed(f, "value does not match bound value")
              return false 
            end
          else
            pv._bind(tv)
          end
        else
          if f.is_a?(RGen::ECore::EAttribute)
            unless pv == tv 
              match_failed(f, "wrong attribute value")
              return false 
            end
          else
            if pv.is_a?(Proxy)
              unless pv._target.object_id == tv.object_id
                match_failed(f, "wrong target object")
                return false 
              end
            else
              unless match_internal(pv, tv, visited, check_later)
                return false 
              end
            end
          end
        end
      end
    end
    true
  end

  def match_failed(f, msg)
    #puts "match failed #{f&&f.eContainingClass.name}##{f&&f.name}: #{msg}"
  end

  def num_pattern_variables(name)
    prok = @patterns[name]
    prok.arity - 1
  end

  def evaluate_pattern(name, env, connection_points)
    prok = @patterns[name]
    raise "unknown pattern #{name}" unless prok
    raise "wrong number of arguments, expected #{prok.arity-1} connection points)" \
      unless connection_points.size == prok.arity-1
    prok.call(env, *connection_points)
  end

  def disconnect_element(element)
    return if element.nil?
    element.class.ecore.eAllStructuralFeatures.reject{|f| f.derived}.each do |f|
      if f.many
        element.setGeneric(f.name, [])
      else
        element.setGeneric(f.name, nil)
      end
    end
  end

  def all_structural_features(element)
    @all_structural_features ||= {}
    return @all_structural_features[element.class] if @all_structural_features[element.class]
    @all_structural_features[element.class] = 
     element.class.ecore.eAllStructuralFeatures.reject{|f| f.derived}
  end

end

end

end

