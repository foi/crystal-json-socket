require "./spec_helper"

struct CustomJSONSocketServer
  include JSONSocket::Server

  def on_message(message, socket)
    message["test"].should eq(1)
    self.send_end_message({:status => "OK"}, socket)
    @stop = true
  end
end

struct CustomJSONSocketServerWithComplexReponse
  include JSONSocket::Server

  def on_message(message, socket)
    message.class.should eq(JSON::Any)
    message["best"].as_s.should eq("no")
    message["test"].to_s.to_i.should eq(1)
    self.send_end_message({ error: nil, data: 138 }, socket)
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

struct CustomJSONSocketServerNonStop
  include JSONSocket::Server

  def on_message(message, socket)
    message["test"].should eq(1)
    self.send_end_message({:status => "OK"}, socket)
  end
end

struct CustomSlowJSONSocketServer
  include JSONSocket::Server

  def on_message(message, socket)
    sleep 2
    self.send_end_message({:status => "OK"}, socket)
  end
end

describe "JSONSocket::Server, JSONSocket::Client" do
  it "Send & receive via tcp" do
    server = CustomJSONSocketServer.new("localhost", 1234)
    spawn server.listen
    to_server = JSONSocket::Client.new("localhost", 1234)
    result = to_server.send({:test => 1})
    if result
      p result.class
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
  it "Receive JSON::Any with NamedTuple via tcp" do
    server = CustomJSONSocketServerWithComplexReponse.new("localhost", 12341)
    spawn server.listen
    to_server = JSONSocket::Client.new("localhost", 12341)
    result = to_server.send({ test: 1, best: "no"})
    if result && result["error"]? && result["data"]?
      result.class.should eq(JSON::Any)
      result["error"].should eq(nil)
      result["data"].to_s.to_i.should eq(138)
    end
  end
  it "Receive JSON::Any with NamedTuple via unix_socket" do
    server = CustomJSONSocketServerWithComplexReponse.new(unix_socket: "./tmp.sock", delimeter: "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new(unix_socket: "./tmp.sock", delimeter: "µ")
    result = to_server.send({ test: 1, best: "no"})
    if result && result["error"]? && result["data"]?
      result.class.should eq(JSON::Any)
      result["error"].should eq(nil)
      result["data"].to_s.to_i.should eq(138)
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

  it "Stress-test via tcp" do
    ch = Channel(String).new
    server = CustomJSONSocketServerNonStop.new("localhost", 13345, "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new("localhost", 13345, "µ")
    start_time = Time.new
    spawn do
      100.times do
        spawn do
          result = to_server.send({:test => 1})
          if result
            ch.send result["status"].as_s
          end
        end
      end
    end
    i = 0
    100.times do
      ok = ch.receive
      i = i + 1
    end
    end_time = Time.new
    puts "result: #{end_time - start_time}"
    i.should eq(100)
  end

  it "read_timeout via tcp" do
    server = CustomSlowJSONSocketServer.new(host: "localhost", port: 12245, delimeter: "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new(host: "localhost", port: 12245, delimeter: "µ", read_timeout: 1)
    expect_raises(IO::Timeout) do
      result = to_server.send({:hello => "ƣŲ21Ɣ"})
    end
  end

  it "read_timeout via unix_socket" do
    server = CustomSlowJSONSocketServer.new(unix_socket: "./tmp-timeout.sock", delimeter: "µ")
    spawn server.listen
    to_server = JSONSocket::Client.new(unix_socket: "./tmp-timeout.sock", delimeter: "µ", read_timeout: 1)
    expect_raises(IO::Timeout) do
      result = to_server.send({:hello => "ƣŲ21Ɣ"})
    end
  end

  it "Stress-test via unix_socket" do
    ch = Channel(String).new
    server = CustomJSONSocketServerNonStop.new(unix_socket: "./tmp-stress.sock", delimeter: "@")
    spawn server.listen
    to_server = JSONSocket::Client.new(unix_socket: "./tmp-stress.sock", delimeter: "@")
    start_time = Time.new
    spawn do
      100.times do
        spawn do
          result = to_server.send({:test => 1})
          if result
            ch.send result["status"].as_s
          end
        end
      end
    end
    i = 0
    100.times do
      ok = ch.receive
      i = i + 1
    end
    end_time = Time.new
    puts "result: #{end_time - start_time}"
    i.should eq(100)
  end
end
