module RGen

# The Transformer class can be used to specify model transformations.
# 
# Model transformations take place between a <i>source model</i> (located in the <i>source
# environment</i> being an instance of the <i>source metamodel</i>) and a <i>target model</i> (located
# in the <i>target environment</i> being an instance of the <i>target metamodel</i>).
# Normally a "model" consists of several model elements associated with each other.
# 
# =Transformation Rules
# 
# The transformation is specified within a subclass of Transformer.
# Within the subclass, the Transformer.transform class method can be used to specify transformation
# blocks for specific metamodel classes of the source metamodel.
# 
# Here is an example:
# 
# 	class MyTransformer < RGen::Transformer
# 
# 		transform InputClass, :to => OutputClass do
# 			{ :name => name, :otherClass => trans(otherClass) }
# 		end
# 
# 		transform OtherInputClass, :to => OtherOutputClass do
# 			{ :name => name }
# 		end
# 	end
# 
# In this example a transformation rule is specified for model elements of class InputClass
# as well as for elements of class OtherInputClass. The former is to be transformed into
# an instance of OutputClass, the latter into an instance of OtherOutputClass.
# Note that the Ruby class objects are used to specifiy the classes.
# 
# =Transforming Attributes
# 
# Besides the target class of a transformation, the attributes of the result object are
# specified in the above example. This is done by providing a Ruby block with the call of
# +transform+. Within this block arbitrary Ruby code may be placed, however the block
# must return a hash. This hash object specifies the attribute assignment of the
# result object using key/value pairs: The key must be a Symbol specifying the attribute
# which is to be assigned by name, the value is the value that will be assigned.
#
# For convenience, the transformation block will be evaluated in the context of the
# source model element which is currently being converted. This way it is possible to just
# write <code>:name => name</code> in the example in order to assign the name of the source 
# object to the name attribute of the target object.
# 
# =Transforming References
# 
# When attributes of elements are references to other elements, those referenced
# elements have to be transformed as well. As shown above, this can be done by calling
# the Transformer#trans method. This method initiates a transformation of the element
# or array of elements passed as parameter according to transformation rules specified
# using +transform+. In fact the +trans+ method is the only way to start the transformation
# at all.
#
# For convenience and performance reasons, the result of +trans+ is cached with respect
# to the parameter object. I.e. calling trans on the same source object a second time will 
# return the same result object _without_ a second evaluation of the corresponding 
# transformation rules.
# 
# This way the +trans+ method can be used to lookup the target element for some source
# element without the need to locally store a reference to the target element. In addition
# this can be useful if it is not clear if certain element has already been transformed
# when it is required within some other transformation block. See example below.
# 
# Special care has been taken to allow the transformation of elements which reference 
# each other cyclically. The key issue here is that the target element of some transformation
# is created _before_ the transformation's block is evaluated, i.e before the elements 
# attributes are set. Otherwise a call to +trans+ within the transformation's block
# could lead to a +trans+ of the element itself.
# 
# Here is an example:
# 
# 	transform ModelAIn, :to => ModelAOut do
# 		{ :name => name, :modelB => trans(modelB) }
# 	end
# 	
# 	transform ModelBIn, :to => ModelBOut do
# 		{ :name => name, :modelA => trans(modelA) }
# 	end
#
# Note that in this case it does not matter if the transformation is initiated by calling
# +trans+ with a ModelAIn element or ModelBIn element due to the caching feature described
# above.
# 
# =Transformer Methods
# 
# When code in transformer blocks becomes more complex it might be useful to refactor
# it into smaller methods. If regular Ruby methods within the Transformer subclass are
# used for this purpose, it is necessary to know the source element being transformed.
# This could be achieved by explicitly passing the +@current_object+ as parameter of the
# method (see Transformer#trans).
# 
# A more convenient way however is to define a special kind of method using the
# Transformer.method class method. Those methods are evaluated within the context of the
# current source element being transformed just the same as transformer blocks are.
# 
# Here is an example:
# 
#		transform ModelIn, :to => ModelOut do
# 		{ :number => doubleNumber }
# 	end
#
# 	method :doubleNumber do
# 		number * 2;
# 	end
#
# In this example the transformation assigns the 'number' attribute of the source element
# multiplied by 2 to the target element. The multiplication is done in a dedicated method
# called 'doubleNumber'. Note that the 'number' attribute of the source element is 
# accessed without an explicit reference to the source element as the method's body
# evaluates in the source element's context.
# 
# =Conditional Transformations
# 
# Using the transformations as described above, all elements of the same class are
# transformed the same way. Conditional transformations allow to transform elements of
# the same class into elements of different target classes as well as applying different
# transformations on the attributes.
# 
# Conditional transformations are defined by specifying multiple transformer blocks for
# the same source class and providing a condition with each block. Since it is important
# to create the target object before evaluation of the transformation block (see above),
# the conditions must also be evaluated separately _before_ the transformer block.
# 
# Conditions are specified using transformer methods as described above. If the return
# value is true, the corresponding block is used for transformation. If more than one
# conditions are true, only the first transformer block will be evaluated.
# 
# Here is an example:
# 
# 	transform ModelIn, :to => ModelOut, :if => :largeNumber do
# 		{ :number => number * 2}
# 	end
#
# 	transform ModelIn, :to => ModelOut, :if => :smallNumber do
# 		{ :number => number / 2 }
# 	end
# 	
# 	method :largeNumber do
# 		number > 1000
# 	end
# 	
# 	method :smallNumber do
# 		number < 500
# 	end
# 
# In this case the transformation of an element of class ModelIn depends on the value
# of the element's 'number' attribute. If the value is greater than 1000, the first rule
# as taken and the number is doubled. If the value is smaller than 500, the second rule
# is taken and the number is divided by two.
# 
# Note that it is up to the user to avoid cycles within the conditions. A cycle could
# occure if the condition are based on transformation target elements, i.e. if +trans+
# is used within the condition to lookup or transform other elements.
# 
class Transformer
	
	TransformationDescription = Struct.new(:block, :target) # :nodoc:
	
	@@methods = {}
	@@transformer_blocks = {}

	def self._transformer_blocks # :nodoc:
		@@transformer_blocks[self] ||= {}
	end

	def self._methods # :nodoc:
		@@methods[self] ||= {}
	end
	
	# This class method is used to specify a transformation rule.
	#
	# The first argument specifies the class of elements for which this rule applies.
	# The second argument must be a hash including the target class
	# (as value of key ':to') and an optional condition (as value of key ':if').
	# 
	# The target class is specified by passing the actual Ruby class object.
	# The condition is either the name of a transformer method (see Transfomer.method) as
	# a symbol or a proc object. In either case the block is evaluated at transformation
	# time and its result value determines if the rule applies.
	# 
	def self.transform(from, desc=nil, &block)
		to = (desc && desc.is_a?(Hash) && desc[:to])
		condition = (desc && desc.is_a?(Hash) && desc[:if])
		raise StandardError.new("No transformation target specified.") unless to
		block_desc = TransformationDescription.new(block, to)
		if condition
			_transformer_blocks[from] ||= {}
			raise StandardError.new("Multiple (non-conditional) transformations for class #{from.name}.") unless _transformer_blocks[from].is_a?(Hash)
			_transformer_blocks[from][condition] = block_desc
		else
			raise StandardError.new("Multiple (non-conditional) transformations for class #{from.name}.") unless _transformer_blocks[from].nil?
			_transformer_blocks[from] = block_desc
		end
	end

	# This class method specifies that all objects of class +from+ are to be copied
	# into an object of class +to+. If +to+ is omitted, +from+ is used as target class.
	# During copy, all attributes according to 
	# MetamodelBuilder::BuilderExtensions.one_attributes and 
	# MetamodelBuilder::BuilderExtensions.many_attributes of the target object
	# are set to their transformed counterparts of the source object.
	# 
	def self.copy(from, to=nil)
		transform(from, :to => to || from) do
			Hash[*(@current_object.class.one_attributes + 
			@current_object.class.many_attributes).inject([]) {|l,a|
				l + [a.to_sym, trans(@current_object.send(a))]
			}]
		end
	end
	
	# Define a transformer method for the current transformer class.
	# In contrast to regular Ruby methods, a method defined this way executes in the
	# context of the object currently being transformed.
	# 
	def self.method(name, &block)
		_methods[name.to_s] = block
	end
	

	# Creates a new transformer with the specified input and output Environment.
	# 
	def initialize(env_in, env_out)
		@env_in = env_in
		@env_out = env_out
		@transformer_results = {}
	end


	# Transforms a given model element according to the rules specified by means of
	# the Transformer.transform	class method.
	# 
	# The transformation result element is created in the output environment and returned.
	# In addition, the result is cached, i.e. a second invocation with the same parameter
	# object will return the same result object without any further evaluation of the 
	# transformation rules. Nil will be transformed into nil.
	# 
	# The transformation input can be given as:
	# * a single object
	# * an array each element of which is transformed in turn
	# * a hash used as input to Environment#find with the result being transformed
	# 
	def trans(obj)
		obj = @env_in.find(obj) if obj.is_a?(Hash)
		return nil if obj.nil?
		return obj if obj.is_a?(TrueClass) or obj.is_a?(FalseClass) or obj.is_a?(Numeric) or obj.is_a?(Symbol)
		return @transformer_results[obj] if @transformer_results[obj]
		return @transformer_results[obj] = obj.dup if obj.is_a?(String)
		return obj.collect{|o| trans(o)}.compact if obj.is_a? Array
		raise StandardError.new("No transformer for class #{obj.class.name}") unless self.class._transformer_blocks[obj.class]
		block_desc = _evaluateCondition(obj)
		return nil unless block_desc
		@transformer_results[obj] = _instantiateTargetClass(obj, block_desc.target)
		old_object, @current_object = @current_object, obj
		block_result = instance_eval(&block_desc.block)
		raise StandardError.new("Transformer must return a hash") unless block_result.is_a? Hash
		@current_object = old_object
		_attributesFromHash(@transformer_results[obj], block_result)
	end

	# Each call which is not handled by the transformer object is passed to the object
	# currently being transformed.
	# If that object also does not respond to the call, it is treated as a transformer
	# method call (see Transformer.method).
	# 
	def method_missing(m) #:nodoc:
		if @current_object.respond_to?(m)
			@current_object.send(m)
		else
			_invokeMethod(m)
		end
	end

	private
		
	# returns the first TransformationDescription for which condition is true :nodoc:
	def _evaluateCondition(obj)
		tb = self.class._transformer_blocks[obj.class]
		block_description = nil
		if tb.is_a?(TransformationDescription)
			# non-conditional
			block_description = tb
		else
			old_object, @current_object = @current_object, obj
			tb.each_pair {|condition, block|
				if condition.is_a?(Proc)
					result = instance_eval(&condition)
				elsif condition.is_a?(Symbol)
					result = _invokeMethod(condition)
				else
					result = condition
				end
				if result
					block_description = block 
					break
				end
			}
			@current_object = old_object
		end
		block_description
	end
	
	def _instantiateTargetClass(obj, target_desc) # :nodoc:
		old_object, @current_object = @current_object, obj
		if target_desc.is_a?(Proc)
			target_class = instance_eval(&target_desc)
		elsif target_desc.is_a?(Symbol)
			target_class = _invokeMethod(target_desc)
		else
			target_class = target_desc
		end
		@current_object = old_object
		@env_out.new target_class
	end
	
	def _invokeMethod(m) # :nodoc:
			raise StandardError.new("Method not found: #{m}") unless self.class._methods[m.to_s]
			instance_eval(&self.class._methods[m.to_s])
	end
		
	def _attributesFromHash(obj, hash) # :nodoc:
		hash.delete(:class)
		hash.each_pair{|k,v|
			obj.send("#{k}=", v)
		}
		obj
	end
	
end

end