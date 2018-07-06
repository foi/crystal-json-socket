require "socket"
require "json"

struct JsonSocketServer
  property host
  property port
  property delimeter
  property buffer

  def initialize(@host : String = "localhost", @port : Int32 = 1234, @delimeter : String = "#")
    @server = TCPServer.new(@host, @port)
    @buffer = String.new
  end

  def send_end_message(socket, message)
    string = message.to_json
    socket.puts "#{string.size}#{@delimeter}#{string}\n"
    socket.close_write
  end

  def listen
    puts "listen..."
    loop do
      if socket = @server.accept?
        tmp = socket.gets
        if tmp
          @buffer = @buffer + tmp
          while !@buffer.index(@delimeter).nil?
            delimeter_index = @buffer.index(@delimeter)
            if delimeter_index
              length = @buffer[0..(delimeter_index - 1)].to_i
              range = (delimeter_index + 1)..(delimeter_index + length)
              message = @buffer[range]
              p "buffer #{@buffer}, buffer.size #{@buffer.size}, range #{range}, length: #{length}"
              @buffer = if @buffer.size == (length + range.begin)
                          ""
                        else
                          @buffer[(delimeter_index + length)..(@buffer.size + 1)]
                        end
              p "Buffer: #{@buffer}, Message: #{message}"
              yield message, socket
            end
          end
        end
      else
        break
      end
    end
  end
end

server = JsonSocketServer.new
server.listen do |message, socket|
  spawn do
    # text = { :name => "111" }.to_json
    # socket.puts "#{text.size}\##{text}\n"
    # socket.close_write
    server.send_end_message(socket, { :name => 222})
  end
end
