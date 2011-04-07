require 'socket'
require 'rtext/completer'
require 'rtext/context_element_builder'

module RText

class Service
  PortRangeStart = 9001
  PortRangeEnd   = 9100

  # Creates an RText frontend support service
  def initialize(lang, service_provider, options={})
    @lang = lang
    @service_provider = service_provider
    @completer = RText::Completer.new(lang) 
    @timeout = options[:timeout] || 60
  end

  def run
    socket = create_socket 
    puts "RText service, listening on port #{socket.addr[1]}"
    $stdout.flush

    last_time = Time.now
    loop do
      begin
        msg, from = socket.recvfrom_nonblock(65000)
      rescue Errno::EWOULDBLOCK
        sleep(0.01)
        break if (Time.now - last_time) > @timeout
        retry
      end
      last_time = Time.now
      lines = msg.split(/\r?\n/)
      cmd = lines.shift
      invocation_id = lines.shift
      response = nil
      case cmd
      when "refresh"
        response = refresh(lines) 
      when "complete"
        response = complete(lines)
      when "show_problems"
        response = get_problems(lines)
      when "get_reference_targets"
        response = get_reference_targets(lines)
      when "get_elements"
        response = get_open_element_choices(lines)
      else
        puts "unknown command #{cmd}"
        response = []
      end
      response.unshift("#{invocation_id}\n")
      response = limit_lines(response, 65000).join
      p response
      socket.send(response, 0, from[2], from[1])
    end
    puts "RText service, stopping now (timeout)"
  end

  private

  def create_socket
    socket = UDPSocket.new
    port = PortRangeStart
    begin
      socket.bind("localhost", port)
    rescue Errno::EADDRINUSE
      port += 1
      retry if port <= PortRangeEnd
      raise
    end
    socket
  end

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

  def refresh(lines)
    @service_provider.load_model
    []
  end

  def complete(lines)
    linepos = lines.shift.to_i
    context = ContextElementBuilder.build_context_element(@lang, lines, linepos)
    puts @lang.identifier_provider.call(context, nil)
    current_line = lines.pop
    options = @completer.complete(current_line, linepos, 
      proc {|i| lines[-i]}, 
      proc {|ref| 
        @service_provider.get_reference_completion_options(ref, context).collect {|o|
          Completer::CompletionOption.new(o.identifier, "<#{o.type}>")}
      })
    options.collect { |o|
      "#{o.text};#{o.extra}\n"
    }
  end

  def get_problems(lines)
    file_name = lines.shift
    # TODO: severity
    @service_provider.get_problems(file_name).collect do |p|
      "#{p.line};#{p.message}\n"
    end
  end

  def get_reference_targets(lines)
    linepos = lines.shift.to_i
    context = ContextElementBuilder.build_context_element(@lang, lines, linepos)
    current_line = lines.last
    result = []
    if current_line[linepos..linepos] =~ /[\w\/]/
      ident_start = (current_line.rindex(/[^\w\/]/, linepos) || -1)+1
      ident_end = (current_line.index(/[^\w\/]/, linepos) || current_line.size)-1
      ident = current_line[ident_start..ident_end]
      result << "#{ident_start};#{ident_end}\n"
      if current_line[0..linepos+1] =~ /^\s*\w+$/
        @service_provider.get_referencing_elements(ident, context).each do |t|
          result << "#{t.file};#{t.line};#{t.display_name}\n"
        end
      else
        @service_provider.get_reference_targets(ident, context).each do |t|
          result << "#{t.file};#{t.line};#{t.display_name}\n"
        end
      end
    end
    result
  end

  def get_open_element_choices(lines)
    pattern = lines.shift
    @service_provider.get_open_element_choices(pattern).collect do |c|
      "#{c.display_name};#{c.file};#{c.line}\n"
    end
  end

end

end

