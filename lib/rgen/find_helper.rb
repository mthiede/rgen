module RGen

module FindHelper
	
	# Finds and returns model elements in the environment.
	# 
	# The search description argument must be a hash specifying attribute/value pairs.
	# Only model elements are returned which respond to the specified attribute methods
	# and return the specified values as result of these attribute methods.
	# 
	# As a special hash key :class can be used to look for model elements of a specific
	# class. In this case an array of possible classes can optionally be given.
	# 
	def find(desc)
		result = []
		classes = desc[:class] if desc[:class] and desc[:class].is_a?(Array)
		classes = [ desc[:class] ] if !classes and desc[:class]
		each {|e|
			failed = false
			failed = true if classes and !classes.any?{ |c| e.is_a?(c) }
			desc.each_pair { |k,v|
				failed = true if k != :class and ( !e.respond_to?(k) or e.send(k) != v )
			}
			result << e unless failed
		}
		result
	end
	
	def findIndex(index_method)
		index = FindIndex.new(index_method)
		each { |e|
			index.add(e)
		}
		index
	end

	class FindIndex
	
		def initialize(index_method)
			@index_method = index_method.to_sym
			@index = {}
			@non_indexed = [].extend(FindHelper)
		end
		
		def add(element)
			if element.respond_to?(@index_method)
				val = element.send(@index_method)
				@index[val] ||= [].extend(FindHelper)
				@index[val] << element
			end
			@non_indexed << element
		end
		
		def find(desc)
			if (desc.keys.include?(@index_method))
				val = desc.delete(@index_method)		
				return [] unless @index[val]
				return @index[val].find(desc)
			else
				return @non_indexed.find(desc)
			end
		end
		
	end
	
end

end
