server = JsonSocketServer.new
server.listen do |message, socket|
  spawn do
    # text = { :name => "111" }.to_json
    # socket.puts "#{text.size}\##{text}\n"
    # socket.close_write
    server.send_end_message(socket, { :name => 222})
  end
end



to_server = JsonSocket.new("localhost", 1234)

10000.times do

  parsed = to_server.send({ :name => 1})
  unless parsed.nil?
    puts parsed["name"]
  end
end
