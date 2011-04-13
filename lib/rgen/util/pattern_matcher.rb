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

  def initialize
    @patterns = {} 
  end

  def add_pattern(name, &block)
    raise "a pattern needs at least 2 block parameters: " + 
      "an RGen environment and a model element as connection point" \
      unless block.arity >= 2
    @patterns[name] = block
  end

  def find_pattern(env, name, *connection_points)
    match = find_pattern_internal(env, name, *connection_points)
    match && match.root
  end

  def insert_pattern(env, name, *connection_points)
    root = evaluate_pattern(name, env, connection_points)
  end

  def remove_pattern(env, name, *connection_points)
    match = find_pattern_internal(env, name, *connection_points)
    if match
      match.elements.each do |e|
        disconnect_element(e)
        env.delete(e)
      end
      match.root
    else
      nil
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

  Match = Struct.new(:root, :elements)
  def find_pattern_internal(env, name, *connection_points)
    proxied_args = connection_points.collect{|a| Proxy.new(a)}
    temp_env = RGen::Environment.new
    pattern_root = evaluate_pattern(name, temp_env, proxied_args)
    env.find(:class => pattern_root.class).each do |e|
      matched = match(pattern_root, e)
      return Match.new(e, matched) if matched 
    end
    nil
  end

  def match(pat_element, test_element, visited={})
    return true if visited[test_element]
    #p [pat_element.class, test_element.class]
    visited[test_element] = true
    unless pat_element.class.ecore == test_element.class.ecore
      match_failed(f, "wrong class")
      return false 
    end
    pat_element.class.ecore.eAllStructuralFeatures.reject{|f| f.derived}.each do |f|
      if f.is_a?(RGen::ECore::EAttribute)
        unless pat_element.getGeneric(f.name) == test_element.getGeneric(f.name)
          match_failed(f, "wrong argument")
          return false 
        end
      else
        pat_targets = pat_element.getGenericAsArray(f.name)
        test_targets = test_element.getGenericAsArray(f.name)
        unless pat_targets.size == test_targets.size
          match_failed(f, "wrong size")
          return false 
        end
        pat_targets.each_with_index do |pt,i|
          tt = test_targets[i]
          if pt.is_a?(Proxy)
            unless pt._target.object_id == tt.object_id
              match_failed(f, "wrong object_id (#{pt._target.shortName} vs #{tt.shortName}")
              return false 
            end
          else
            unless match(pt, tt, visited)
              return false 
            end
          end
        end
      end
    end
    visited.keys
  end

  def match_failed(f, msg)
    #puts "match failed #{f.eContainingClass.name}##{f.name}: #{msg}"
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

end

end

end

