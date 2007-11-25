require 'rgen/find_helper'

module RGen

# An Environment is used to hold model elements.
#
class Environment
	include RGen::FindHelper

	def initialize
		@elements = []
	end
	
	# Add a model element. Returns the environment so <code><<</code> can be chained.
	# 
	def <<(el)
		@elements << el
		self
	end
	
	# Removes model element from environment.
	def delete(el)
		@elements.delete(el)
	end
		
	# Iterates each element
	#
	def each(&b)
		@elements.each(&b)
	end
	
	# Return the elements of the environment as an array
	#
	def elements
		@elements.dup
	end
	
	# This method can be used to instantiate a class and automatically put it into
	# the environment. The new instance is returned.
	#
	def new(clazz, *args)
		@elements << clazz.new(*args)
		@elements[-1]
	end
end
	
end