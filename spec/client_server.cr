require "./spec_helper"

describe "JSONSocket::Server, JSONSocket::Client" do
  it "Server should receive and repond on messages and clinet should send and receive response from server" do
    server = JSONSocket::Server.new("localhost", 1234)
    spawn do
      server.listen do |message, socket|
        message["test"].should eq(1)
        server.send_end_message(socket, { :status => "success" })
        server.stop
      end
    end
    to_server = JSONSocket::Client.new("localhost", 1234)
    result = to_server.send({ :test => 1 })
    if result
      result["status"].should eq("success")
    end
  end
end
