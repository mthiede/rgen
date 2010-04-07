class JsonParser

rule

  json: value { result = val[0] }

  array: "[" valueList "]" { result = val[1] }
    | "[" "]" { result = [] }

  valueList: value { result = [ val[0] ] }
    | value "," valueList { result = [ val[0] ] + val[2] }

  object: "{" memberList "}" { result = @instantiator.createObject(val[1]) }
    | "{" "}" { result = nil }

  memberList: member { result = val[0] }
    | member "," memberList { result = val[0].merge(val[2]) } 

  member: STRING ":" value { result = {val[0].value => val[2]} }

  value: array { result = val[0] }
    | object { result = val[0] }
    | STRING { result = val[0].value }
    | INTEGER { result = val[0].value.to_i }
    | FLOAT { result = val[0].value.to_f }
    | "true" { result = true }
    | "false" { result = false }

end

---- header

module ConcreteSupport

---- inner

	ParserToken = Struct.new(:line, :file, :value)

  def initialize(instantiator)
    @instantiator = instantiator
  end
     	
	def parse(str, file=nil)
		@q = []
		line = 1
		
		until str.empty?
			case str
				when /\A\n/
					str = $'
					line +=1
				when /\A\s+/
					str = $'
				when /\A([-+]?\d+)/
					str = $'
					@q << [:INTEGER, ParserToken.new(line, file, $1)]
				when /\A([-+]?\d+\.\d+)/
					str = $'
					@q << [:FLOAT, ParserToken.new(line, file, $1)]
				when /\A"([^"]*)"/
					str = $'
					@q << [:STRING, ParserToken.new(line, file, $1)]
				when /\A(\{|\}|\[|\]|,|:|true|false)/
					str = $'
					@q << [$1, ParserToken.new(line, file, $1)]
			end
		end
		@q.push [false, ParserToken.new(line, file, '$end')]
		do_parse
	end
	
	def next_token
		r = @q.shift
    r
	end
	
---- footer

end

