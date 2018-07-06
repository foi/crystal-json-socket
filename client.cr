require "socket"
require "json"

struct JsonSocket
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
      STDERR.puts ex.message
    end
  end
end


to_server = JsonSocket.new("localhost", 1234)

10000.times do

  parsed = to_server.send({ :name => 1})
  unless parsed.nil?
    puts parsed["name"]
  end
end
