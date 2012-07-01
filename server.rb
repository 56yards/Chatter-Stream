require "rubygems"
require "bundler"
Bundler.setup
require "em-websocket"

class Client
  attr_accessor :ws
  attr_accessor :username
  
  def initialize(ws, username)  
      @ws, @username = ws,username  
  end
  
end


class ChatRoom
  
  attr_accessor :clients
  
  def initialize
    @clients = []
  end
  
  def start(opts={})
    EventMachine::WebSocket.start(opts) do |ws|
      ws.onopen { add_client(ws, ws.request["query"]["username"]) }
      ws.onclose { remove_client(ws) }
      ws.onmessage { |msg| handle_message(ws, msg) }
    end
  end
  
  def add_client(ws, username)
    client = Client.new(ws, username)
    @clients << client
    
    alert_all_clients("#{client.username}: has joined the conversation.")
    send_existing_users(client)
  end
  
  def send_existing_users(client)
    msg = "users:"
    
    @clients.each do |client|
        msg += client.username + ","
    end
    
    client.ws.send msg
  end
  
  def alert_all_clients(msg)
    @clients.each do |client|
      client.ws.send msg
    end
  end
  
  def remove_client(ws)
    client1 = nil
    @clients.each_with_index do |client, i|
      if client.ws == ws then
        client1 = client
        @clients.delete_at(i)
      end
    end
    
    alert_all_clients("#{client1.username}: has left the conversation.")
  end
  
  def handle_message(ws, msg)
    client1 = nil
    @clients.each do |client|
      if client.ws == ws then
        client1 = client
      end
    end
    
    unless msg.empty?
      alert_all_clients("#{client1.username}: " + msg)
    end
  end
  
end


chatroom = ChatRoom.new
chatroom.start(:host => "0.0.0.0", :port => 3001)