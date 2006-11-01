# RGen Framework
# (c) Martin Thiede, 2006

require 'erb'
require 'rgen/metamodel_builder/build_helper'

module RGen

module MetamodelBuilder

# This module provides methods which can be used to setup a metamodel element.
# The module is used to +extend+ MetamodelBuilder::MMBase, i.e. add the module's 
# methods as class methods.
# 
# MetamodelBuilder::MMBase should be used as a start for new metamodel elements.
# See MetamodelBuilder for an example.
# 
module BuilderExtensions

	# Add a single attribute or unidirectional association.
	# 'role' specifies the name which is used to access the attribute.
	# 'target_class' is optional and can be used to fix the type of objects which
	# can be held by this attribute.
	# 
	# This class method adds the following instance methods, where 'role' is to be 
	# replaced by the given role name:
	# 	class#role	# getter
	# 	class#role=(value)	# setter
	# 
	def has_one(role, target_class=nil)
		has_one_internal(role, target_class)
	end

	# Add an unidirectional _many_ association.
	# 'role' specifies the name which is used to access the attribute.
	# 'target_class' is optional and can be used to fix the type of objects which
	# can be referenced by this association.
	# 
	# This class method adds the following instance methods, where 'role' is to be 
	# replaced by the given role name:
	# 	class#addRole(value)	
	# 	class#removeRole(value)
	# 	class#role	# getter, returns an array
	# Note that the first letter of the role name is turned into an uppercase 
	# for the add and remove methods.
	# 
	def has_many(role, target_class=nil)
		has_many_internal(role, target_class)
	end
	
	# Add a bidirectional one-to-many association between two classes.
	# The class this method is called on is refered to as _own_class_ in 
	# the following.
	# 
	# Instances of own_class can use 'own_role' to access _many_ associated instances
	# of type 'target_class'. Instances of 'target_class' can use 'target_role' to
	# access _one_ associated instance of own_class.
	# 
	# This class method adds the following instance methods where 'ownRole' and
	# 'targetRole' are to be replaced by the given role names:
	# 	own_class#addOwnRole(value)
	# 	own_class#removeOwnRole(value)
	# 	own_class#ownRole
	# 	target_class#targetRole
	# 	target_class#targetRole=(value)
	# Note that the first letter of the role name is turned into an uppercase 
	# for the add and remove methods.
	# 
	# When an element is added/set on either side, this element also receives the element
	# is is added to as a new element.
	# 
	def one_to_many(own_role, target_class, target_role)
		has_many_internal(own_role,target_class,target_role,:one)
		target_class.has_one_internal(target_role,self,own_role,:many)
	end
	
	# This is the inverse of one_to_many provided for convenience.
	def many_to_one(own_role, target_class, target_role)
		has_one_internal(own_role,target_class,target_role,:many)
		target_class.has_many_internal(target_role,self,own_role,:one)
	end
	
	# Add a bidirectional many-to-many association between two classes.
	# The class this method is called on is refered to as _own_class_ in 
	# the following.
	# 
	# Instances of own_class can use 'own_role' to access _many_ associated instances
	# of type 'target_class'. Instances of 'target_class' can use 'target_role' to
	# access _many_ associated instances of own_class.
	# 
	# This class method adds the following instance methods where 'ownRole' and
	# 'targetRole' are to be replaced by the given role names:
	# 	own_class#addOwnRole(value)
	# 	own_class#removeOwnRole(value)
	# 	own_class#ownRole
	# 	target_class#addTargetRole
	# 	target_class#removeTargetRole=(value)
	# 	target_class#targetRole
	# Note that the first letter of the role name is turned into an uppercase 
	# for the add and remove methods.
	# 
	# When an element is added on either side, this element also receives the element
	# is is added to as a new element.
	# 
	def many_to_many(own_role, target_class, target_role)
		has_many_internal(own_role,target_class,target_role,:many)
		target_class.has_many_internal(target_role,self,own_role,:many)
	end
	
	# Add a bidirectional one-to-one association between two classes.
	# The class this method is called on is refered to as _own_class_ in 
	# the following.
	# 
	# Instances of own_class can use 'own_role' to access _one_ associated instance
	# of type 'target_class'. Instances of 'target_class' can use 'target_role' to
	# access _one_ associated instance of own_class.
	# 
	# This class method adds the following instance methods where 'ownRole' and
	# 'targetRole' are to be replaced by the given role names:
	# 	own_class#ownRole
	# 	own_class#ownRole=(value)
	# 	target_class#targetRole
	# 	target_class#targetRole=(value)
	# 
	# When an element is set on either side, this element also receives the element
	# is is added to as the new element.
	# 
	def one_to_one(own_role, target_class, target_role)
		has_one_internal(own_role,target_class,target_role,:one)
		target_class.has_one_internal(target_role,self,own_role,:one)
	end
	
	# Returns the names of the classes attributes pointing to a single object.
	# The result includes this kind of attributes of the superclass.
	def one_attributes
		@one_attributes ||= []
		result = @one_attributes.dup
		result += superclass.one_attributes if superclass.respond_to?(:one_attributes)
		result
	end
	
	# Returns the names of the classes attributes pointing to many other objects
	# The result includes this kind of attributes of the superclass.
	def many_attributes
		@many_attributes ||= []
		result = @many_attributes.dup
		result += superclass.many_attributes if superclass.respond_to?(:many_attributes)
		result
	end
	
	protected
	
	def has_one_internal(name, cls=nil, role=nil, kind=nil)
		@one_attributes ||= []
		return if @one_attributes.include?(name)
		@one_attributes << name
		BuildHelper.build self, binding, <<-CODE
			def #{name}=(val)
				return if val == @#{name}
				<% if cls %>
					raise _assignmentTypeError(self,val,#{cls}) unless val.nil? or val.is_a? #{cls}
				<% end %>
				oldval = @#{name}
				@#{name} = val
				_unregister(self,oldval,"#{role}","#{kind}")
				_register(self,val,"#{role}","#{kind}")
			end 
			def #{name}
				@#{name}
			end
			alias get<%= firstToUpper(name) %> #{name}
			alias set<%= firstToUpper(name) %> #{name}=
		CODE
	end
	
	def has_many_internal(name, cls=nil, role=nil, kind = nil)
		@many_attributes ||= []
		return if @many_attributes.include?(name)
		@many_attributes << name
		BuildHelper.build self, binding, <<-CODE
			def add<%= firstToUpper(name) %>(val)
				@#{name} = [] unless @#{name}
				return if val.nil? or @#{name}.include?(val) 
				<% if cls %>
					raise _assignmentTypeError(self,val,#{cls}) unless val.nil? or val.is_a? #{cls}
				<% end %>
				@#{name}.push val
				_register(self, val, "#{role}", "#{kind}")
			end
			def remove<%= firstToUpper(name) %>(val)
				@#{name} = [] unless @#{name}
				return unless @#{name}.include?(val)
				@#{name}.delete val
				_unregister(self, val, "#{role}", "#{kind}")
			end
			def #{name}
				( @#{name} ? @#{name}.dup : [] )
			end
			def #{name}=(val)
				return if val.nil?
				raise _assignmentTypeError(self, val, Array) unless val.is_a? Array
				#{name}.each {|e|
					remove<%= firstToUpper(name) %>(e)
				}
				val.each {|v|
					add<%= firstToUpper(name) %>(v)
				}
			end
			alias get<%= firstToUpper(name) %> #{name}
			alias set<%= firstToUpper(name) %> #{name}=
		CODE
	end	

end
end

end