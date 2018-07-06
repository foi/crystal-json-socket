require "socket"
require "json"

struct Client
  property host
  property port
  property delimeter

  def initialize(@host : String, @port : Int16, @delimeter : String = "#")
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
