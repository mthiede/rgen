# RGen Framework
# (c) Martin Thiede, 2006

require 'rgen/metamodel_builder/builder_runtime'
require 'rgen/metamodel_builder/builder_extensions'

module RGen

# MetamodelBuilder can be used to create a metamodel, i.e. Ruby classes which
# act as metamodel elements.
# 
# To create a new metamodel element, create a Ruby class which inherits from
# MetamodelBuilder::MMBase
# 
# 	class Person < RGen::MetamodelBuilder::MMBase
# 	end
# 
# This way a couple of class methods are made available to the new class.
# These methods can be used to:
# * add attributes to the class
# * add associations with other classes
# 
# Here is an example:
# 
# 	class Person < RGen::MetamodelBuilder::MMBase
# 		has_one 'name', String
# 		has_one 'age', Integer
# 	end
# 
# 	class House < RGen::MetamodelBuilder::MMBase
# 		has_one 'address'
# 	end
# 
# 	Person.many_to_many 'homes', House, 'inhabitants'
# 
# See BuilderExtensions for details about the available class methods.
# 
# =Attributes
# 
# The example above creates two classes 'Person' and 'House'. Person has the attributes
# 'name' and 'age', House has the attribute 'address'. The attributes can be 
# accessed on instances of the classes in the following way:
# 
# 	p = Person.new
# 	p.name = "MyName"
# 	p.age = 22
# 	p.name	# => "MyName"
# 	p.age 	# => 22
# 
# Note that the class Person takes care of the type of its attributes. As 
# declared above, a 'name' can only be a String, an 'age' must be an Integer.
# So the following would return an exception:
# 
# 	p.name = :myName	# => exception: can not put a Symbol where a String is expected
# 
# If the type of an attribute should be left undefined, just leave away the
# second argument of 'has_one' as show at the attribute 'address' for House.
#
# =Associations
# 
# As well as attributes show up as instance methods, associations bring their own
# accessor methods. For the Person-to-House association this would be:
# 
# 	h1 = House.new
# 	h1.address = "Street1"
# 	h2 = House.new
# 	h2.address = "Street2"
# 	p.addHomes(h1)
# 	p.addHomes(h2)
# 	p.removeHomes(h1)
# 	p.homes	# => [ h2 ]
# 
# The Person-to-House association is _bidirectional_. This means that with the 
# addition of a House to a Person, the Person is also added to the House. Thus:
# 
# 	h1.inhabitants	# => []
# 	h2.inhabitants	# => [ p ]
# 	
# Note that the association is defined between two specific classes, instances of
# different classes can not be added. Thus, the following would result in an 
# exception:
# 
# 	p.addHomes(:justASymbol) # => exception: can not put a Symbol where a House is expected
# 
# _Unidirectional_ associations can be thought of as attributes as shown above. This means 
# that 'has_one' or 'has_many' can be used to define such associations. Again, the
# type of the attribute/association can be specified as a second argument.
# 
module MetamodelBuilder	

	# Use this class as a start for new metamodel elements (i.e. Ruby classes)
	# by inheriting for it.
	# 
	# See MetamodelBuilder for an example.
	class MMBase
		include BuilderRuntime
		extend BuilderExtensions
	end

end

end