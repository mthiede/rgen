# RGen Framework
# (c) Martin Thiede, 2006

module RGen

module TemplateLanguage

class OutputHandler
	attr_writer :indent
	
	def initialize(indent=0, mode=:explicit)
		self.mode = mode
		@indent = indent
		@state = :wait_for_nonws
		@output = ""
	end
		
	def concat(s)
		return @output.concat(s) if s.is_a? OutputHandler
		s = s.to_str.gsub(/^[\t ]*\r?\n/,'') if @ignoreNextNL
		s = s.to_str.gsub(/^\s+/,'') if @ignoreNextWS
		@ignoreNextNL = @ignoreNextWS = false if s =~ /\S/
		if @mode == :direct
			@output.concat(s)
		elsif @mode == :explicit
			while s.size > 0
				#puts "DEGUB: #{@state} #{s.dump}"
				# s starts with whitespace
				if s =~ /\A(\s+)(.*)/m	
					ws = $1; rest = $2
					#puts "DEGUB: ws #{ws.dump} rest #{rest.dump}"
					if @state == :wait_for_nl
						# ws contains a newline
						if ws =~ /\A[\t ]*(\r?\n)(\s*)/m
							@output.concat($1)
							@state = :wait_for_nonws
							s = $2 + rest
						else
							@output.concat(ws)
							s = rest
						end
					else
						s = rest
					end
				# s starts with non-whitespace
				elsif s =~ /\A(\S+)(.*)/m
					nonws = $1; rest = $2
					#puts "DEGUB: nonws #{nonws.dump} rest #{rest.dump}"
					@output.concat("   "*@indent) if @state == :wait_for_nonws
					@output.concat(nonws)
					@state = :wait_for_nl
					s = rest
				end
			end
		end
	end
	alias << concat
	
	def to_str
		@output
	end
	alias to_s to_str

	def direct_concat(s)
		@output.concat(s)
	end
			
	def ignoreNextNL
		@ignoreNextNL = true
	end
	
	def ignoreNextWS
		@ignoreNextWS = true
	end
	
	def mode=(m)
		raise StandardError.new("Unknown mode: #{m}") unless [:direct, :explicit].include?(m)
		@mode = m
	end
end

end

end