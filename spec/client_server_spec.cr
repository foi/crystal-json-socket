require "./spec_helper"

describe "JSONSocket::Server, JSONSocket::Client" do
  it "Send & receive via tcp" do
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
  it "Send & receive via tcp with custom delimeter like µ" do
    server = JSONSocket::Server.new(host: "localhost", port: 12345, delimeter: "µ")
    spawn do
      server.listen do |message, socket|
        message["test"].should eq(1)
        server.send_end_message(socket, { :status => "success" })
        server.stop
      end
    end
    to_server = JSONSocket::Client.new(host: "localhost", port: 12345, delimeter: "µ")
    result = to_server.send({ :test => 1 })
    if result
      result["status"].should eq("success")
    end
  end
  it "Send & receive via unix_socket" do
    server = JSONSocket::Server.new(unix_socket: "./json-socket-server.sock")
    spawn do
      server.listen do |message, socket|
        message["test"].should eq(1)
        server.send_end_message(socket, { :status => "success" })
        server.stop
      end
    end
    to_server = JSONSocket::Client.new(unix_socket: "./json-socket-server.sock")
    result = to_server.send({ :test => 1 })
    if result
      result["status"].should eq("success")
    end
  end
  it "Send & receive via unix_socket with custom delimeter like µ" do
    server = JSONSocket::Server.new(unix_socket: "./json-socket-server.sock", delimeter: "µ")
    spawn do
      server.listen do |message, socket|
        message["test"].should eq(1)
        server.send_end_message(socket, { :status => "success" })
        server.stop
      end
    end
    to_server = JSONSocket::Client.new(unix_socket: "./json-socket-server.sock", delimeter: "µ")
    result = to_server.send({ :test => 1 })
    if result
      result["status"].should eq("success")
    end
  end
end
