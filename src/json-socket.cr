require "socket"
require "json"

module JSONSocket
  struct Client
    property host
    property port
    property delimeter

    def initialize(@host : String, @port : Int32, @delimeter : String = "#")
    end

    def send(object)
      begin
        TCPSocket.open(@host, @port) do |socket|
          stringified = object.to_json
          socket << "#{stringified.size}#{delimeter}#{stringified}\n"
          response = socket.gets
          unless response.nil?
            parts = response.split(@delimeter)
            return JSON.parse(parts[1])
          else
            raise "failed while receiving response!"
          end
        end
      rescue ex
        puts ex.message
      end
    end
  end

  struct Server
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
                @buffer = if @buffer.size == (length + range.begin)
                            ""
                          else
                            @buffer[(delimeter_index + length)..(@buffer.size + 1)]
                          end
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
end
