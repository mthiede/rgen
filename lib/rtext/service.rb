require 'socket'
require 'rtext/completer'
require 'rtext/instantiator'

module RText

class Service

  # Creates an RText frontend support service
  def initialize(lang, options={})
    @completer = RText::Completer.new(lang) 
    @instantiator = RText::Instantiator.new(lang)
    @timeout = options[:timeout] || 60
  end

  def run
    socket = UDPSocket.new
    port = 9001
    socket.bind("localhost", port)
    puts "RText service, listening on port #{port}"

    start_time = Time.now
    loop do
      begin
        msg, from = socket.recvfrom_nonblock(65000)
      rescue Errno::EWOULDBLOCK
        sleep(0.01)
        break if (Time.now - start_time) > @timeout
        retry
      end
      lines = msg.split(/\r?\n/)
      lines << "" if msg[-1] == ?\n
      cmd = lines.shift
      response = nil
      case cmd
      when "complete"
        response = complete(lines).unshift("complete\n")
      when "show_problems"
        response = check(lines).unshift("show_problems\n") 
      else
        puts "unknown command #{cmd}"
        response = ""
      end
      response = limit_lines(response, 65000).join
      socket.send(response, 0, from[2], from[1])
    end
    puts "RText service, stopping now (timeout)"
  end

  private

  def limit_lines(lines, bytes)
    result = []
    size = 0
    lines.each do |l|
      size += l.size
      break if size > bytes
      result << l
    end
    result
  end 

  def complete(lines)
    current_line = lines.pop
    options = @completer.complete(current_line, proc {|i| lines[-i]})
    options.collect { |o|
      "#{o.text};#{o.extra}\n"
    }
  end

  def check(lines)
    file_name = lines.shift
    problems = []
    File.open(file_name) do |f|
      @instantiator.instantiate(f.read, :problems => problems)
    end
    problems.collect { |p|
      "#{file_name}:#{p.line}:#{p.message}\n"  
    }
  end

end

end

