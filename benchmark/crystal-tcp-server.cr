require "../src/json-socket.cr"

struct CustomJSONSocketServer

  include JSONSocket::Server

  def on_message(message, socket)
    puts message
    result = (message["a"].as_i + message["b"].as_i) * message["b"].as_i * message["a"].as_i
    self.send_end_message(socket, { :result => result })
  end

end

server = CustomJSONSocketServer.new(host: "127.0.0.1", port: 1234, node_json_socket_compatibility: true)
server.listen
