require "socket"
require "json"

struct JsonSocket
  property host
  property port
  property delimeter

  def initialize(@host : String, @port : Int16, @delimeter : String = "#")
    @socket = TCPSocket.new(@host, @port)
  end

  def send(object)
    begin
      stringified = object.to_json
      @socket << "#{stringified.size}#{delimeter}#{stringified}\n"
      response = @socket.gets
      unless response.nil?
        parts = response.split(@delimeter)
        return JSON.parse(parts[1])
      else
        raise "failed while receiving response!"
      end
    rescue ex
      puts ex.message
    end
  end
end

to_server = JsonSocket.new("localhost", 1234)
parsed = to_server.send({ :name => 1})
unless parsed.nil?
  puts parsed["name"]
end


# start_time = Time.now
#
#
#   client = TCPSocket.new("localhost", 1234)
#   client << "15\#{\"type\":\"ping\"}\n"
#   response = client.gets
#   #p response
#
#
