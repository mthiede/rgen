# RGen Framework
# (c) Martin Thiede, 2006

module RGen

module NameHelper
	def normalize(name)
		name.gsub(/[\.:]/,'_')
	end
	def className(object)
		object.class.name =~ /::(\w+)$/; $1
	end
	def firstToUpper(str)
		str[0..0].upcase + ( str[1..-1] || "" )
	end
	def firstToLower(str)
		str[0..0].downcase + ( str[1..-1] || "" )
	end
end

end