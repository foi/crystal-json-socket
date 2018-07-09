require "../src/json-socket.cr"
to_server = JSONSocket::Client.new(host: "localhost", port: 1234)
channel = Channel(Int32).new
start_time = Time.now
10000.times do |i|
  spawn do
    result = to_server.send({ a: 12, b: 8})
    channel.send(i)
  end
end
count = 0
10000.times do
  value = channel.receive
  count = count + 1
  if count == 9999
    puts "Elapsed time: #{(Time.now - start_time)}"
  end
end
