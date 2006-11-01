module RGen

# An Environment is used to hold model elements.
#
class Environment

	def initialize
		@elements = []
	end
	
	# Add a model element. Returns the environment so <code><<</code> can be chained.
	# 
	def <<(el)
		@elements << el
		self
	end
	
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
		elements.each {|e|
			failed = false
			failed = true if classes and !classes.any?{ |c| e.is_a?(c) }
			desc.each_pair { |k,v|
				failed = true if k != :class and ( !e.respond_to?(k) or e.send(k) != v )
			}
			result << e unless failed
		}
		result
	end
	
	# Return the elements of the environment as an array
	#
	def elements
		@elements.dup
	end
	
	# This method can be used to instantiate a class and automatically put it into
	# the environment. The new instance is returned.
	#
	def new(clazz)
		@elements << clazz.new
		@elements[-1]
	end
end
	
end