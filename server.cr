require "socket"
require "json"

struct 


DELIMITER = "#"

def handle_client(client)
  message = client.gets
  if message
    puts 1
    puts message.split(DELIMITER)
    puts message.size
    delimiter_index = message.index(DELIMITER)
    if delimiter_index
      length = message[0..(delimiter_index - 1)].to_i
      range = (delimiter_index + 1)..(delimiter_index + length)
      puts length
      puts message[range]
    end
    client.puts message
    client.close_write
  end
end

server = TCPServer.new("localhost", 1234)
loop do
  if socket = server.accept?
    # handle the client in a fiber
    spawn handle_client(socket)
  else
    # another fiber closed the server
    break
  end
end
