require "socket"
require "json"
require "file_utils"

module JSONSocket
  class Client
    def initialize(@host = "localhost", @port = 1234, @delimeter = "#", @unix_socket : String? = nil, @read_timeout : Int8 = 5, @write_timeout : Int8 = 2)
    end

    def send(object)
      if @unix_socket
        UNIXSocket.open(@unix_socket.as(String)) do |socket|
          socket.read_timeout = @read_timeout
          socket.write_timeout = @write_timeout
          handle_send_receive(socket, object)
        end
      else
        TCPSocket.open(@host, @port) do |socket|
          socket.read_timeout = @read_timeout
          socket.write_timeout = @write_timeout
          handle_send_receive(socket, object)
        end
      end
    end

    def handle_send_receive(socket, object)
      stringified = object.to_json
      socket << "#{stringified.bytesize}#{@delimeter}#{stringified}"
      response = socket.gets
      if !response.nil?
        parts = response.split(@delimeter)
        return JSON.parse(parts[1])
      else
        raise "fail while receiving response!"
      end
    ensure
      socket.close
    end
  end

  module Server
    def initialize(host : String = "localhost", port : Int32 = 1234, delimeter : String = "#", unix_socket = nil)
      @delimeter = delimeter
      @server = if unix_socket
                  FileUtils.rm(unix_socket.as(String)) if File.exists?(unix_socket.as(String))
                  UNIXServer.new(unix_socket)
                else
                  TCPServer.new(host, port)
                end
      @stop = false
    end

    def send_end_message(message, socket)
      string = message.to_json
      socket.puts "#{string.size}#{@delimeter}#{string}"
    ensure
      socket.close
    end

    def stop
      @stop = true
    end

    def listen
      loop do
        break if @stop
        while client = @server.accept?
          spawn handle_socket(client)
        end
      end
    end

    def on_message(message, socket)
      puts "Default on_message methods - please override, like this: \n" \
           "class CustomJSONSocketServer \n" \
           "  include JSONSocket::Server \n" \
           " \n" \
           "  def on_message(message, socket) \n" \
           "    puts message \n" \
           "    response = { :status => \"OK\"}.to_json \n" \
           "    self.send_end_message({ :hello => 892 }, socket) \n" \
           "  end \n" \
           "end \n"
    end

    def handle_socket(socket)
      if socket
        message_size = socket.gets(@delimeter).not_nil!.delete(@delimeter).to_i
        message = socket.read_string(message_size)
        begin
          on_message(JSON.parse(message), socket)
        rescue ex
          STDERR.puts ex.message
        end
      end
    end
  end
end
