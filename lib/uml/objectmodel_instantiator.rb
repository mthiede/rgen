module ObjectmodelInstantiator

	def instantiateObjectModel(env_in, env_out, metamodel)
		objectMap = {}
		env_in.find(:class => UMLObjectModel::UMLObject).each do |o_in|
			o_out = env_out.new metamodel.const_get(o_in.classname)
			objectMap[o_in] = o_out
			o_out.name = o_in.name
			o_in.attributeSettings.each { |as|
				conversions = ["to_s", "to_i", "to_f"]
				conv = conversions.first
				begin
					o_out.send(as.name+"=",as.value.send(conv))
				rescue StandardError
					conv = conversions[conversions.index(conv)+1]
					retry if conv
					raise
				end
			}
		end
		env_in.find(:class => UMLObjectModel::UMLAssociation).each do |a_in|
			begin
				if a_in.roleA
					begin
						o_out = objectMap[a_in.objectB]
						es = o_out.send(a_in.roleA)
					rescue NoMethodError
						raise StandardError.new("In #{o_out.class.name}(#{o_out.name}): method not found #{a_in.roleA}")
					end
					if es.is_a? RGen::MetamodelBuilder::ElementSet
						es << objectMap[a_in.objectA]
					else
						objectMap[a_in.objectB].send(a_in.roleA+"=", objectMap[a_in.objectA])
					end
				elsif a_in.roleB
					begin
						o_out = objectMap[a_in.objectA]
						es = o_out.send(a_in.roleB)
					rescue NoMethodError
						raise StandardError.new("In #{o_out.class.name}(#{o_out.name}): method not found #{a_in.roleB}")
					end
					if es.is_a? RGen::MetamodelBuilder::ElementSet
						es << objectMap[a_in.objectB]
					else
						objectMap[a_in.objectA].send(a_in.roleB+"=", objectMap[a_in.objectB])
					end
				end
			rescue StandardError => e
				puts e.message
			end
		end
	end
end