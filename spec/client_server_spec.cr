require "./spec_helper"

struct CustomJSONSocketServer
  include JSONSocket::Server

  def on_message(message, socket)
    message["test"].should eq(1)
    self.send_end_message({:status => "OK"}, socket)
    @stop = true
  end
end

struct CustomCyrillicJSONSocketServer
  include JSONSocket::Server

  def on_message(message, socket)
    message["hello"].should eq("привет")
    self.send_end_message({:hi => "и тебе привет"}, socket)
    @stop = true
  end
end

struct CustomUnicodeJSONSocketServer
  include JSONSocket::Server

  def on_message(message, socket)
    message["hello"].should eq("ƣŲ21Ɣ")
    self.send_end_message({:hi => "ŤŢ32Ɓ"}, socket)
    @stop = true
  end
end

describe "JSONSocket::Server, JSONSocket::Client" do
  it "Send & receive via tcp" do
    server = CustomJSONSocketServer.new("localhost", 1234)
    spawn server.listen
    to_server = JSONSocket::Client.new("localhost", 1234)
    result = to_server.send({:test => 1})
    if result
      result["status"].should eq("OK")
    end
  end
  it "Send & receive via tcp with custom delimeter" do
    server = CustomJSONSocketServer.new("localhost", 12345, "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new("localhost", 12345, "µ")
    result = to_server.send({:test => 1})
    if result
      result["status"].should eq("OK")
    end
  end
  it "Send & receive via unix_socket" do
    server = CustomJSONSocketServer.new(unix_socket: "./tmp.sock")
    spawn server.listen
    to_server = JSONSocket::Client.new(unix_socket: "./tmp.sock")
    result = to_server.send({:test => 1})
    if result
      result["status"].should eq("OK")
    end
  end
  it "Send & receive via unix_socket with custom delimeter" do
    server = CustomJSONSocketServer.new(unix_socket: "./tmp.sock", delimeter: "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new(unix_socket: "./tmp.sock", delimeter: "µ")
    result = to_server.send({:test => 1})
    if result
      result["status"].should eq("OK")
    end
  end
  it "Send & receive via unix_socket with custom delimeter & unicode message" do
    server = CustomCyrillicJSONSocketServer.new(unix_socket: "./tmp.sock", delimeter: "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new(unix_socket: "./tmp.sock", delimeter: "µ")
    result = to_server.send({:hello => "привет"})
    if result
      result["hi"].should eq("и тебе привет")
    end
  end
  it "Send & receive via unix_socket with custom delimeter & unicode message" do
    server = CustomUnicodeJSONSocketServer.new(unix_socket: "./tmp.sock", delimeter: "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new(unix_socket: "./tmp.sock", delimeter: "µ")
    result = to_server.send({:hello => "ƣŲ21Ɣ"})
    if result
      result["hi"].should eq("ŤŢ32Ɓ")
    end
  end
end
