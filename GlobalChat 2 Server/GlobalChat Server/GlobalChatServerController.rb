require 'net/http'


# just a delegate to the GServer
class GlobalChatServerController

  attr_accessor :gchatserv, :application

  attr_accessor :server_name, :password, :server_status, :publicize_button, :published, :host

  $queue = Dispatch::Queue.new('com.mdx.globalchat')

  def checkStatus # change server setting
    if @gchatserv.stopped?
      @server_status.setStringValue("Stopped")
    else
      @server_status.setStringValue("Running")
      @gchatserv.password = @password.stringValue
      @publicize_button.setEnabled (@host.stringValue != "" && @server_name.stringValue != "" && @published == false)
    end
  end

  def quit(sender)
    if @server_name.stringValue != "" && @published == true
        nexus_offline
    end
    @application.terminate(self)
  end


  def pingNexus(sender)
    $queue.async do
      ping_nexus
    end
  end

  def ping_nexus
    NSLog "Pinging NexusNet that I'm Online!!"
    host = @host.stringValue
    chatnet_name = @server_name.stringValue
    port = 9994
    uri = URI.parse("http://nexusnet.herokuapp.com/online")
    query = {:name => chatnet_name, :port => port, :host => host}
    uri.query = URI.encode_www_form( query )
    Net::HTTP.get(uri)
    @published = true
  end

  def nexus_offline
    NSLog "Informing NexusNet that I have exited!!!"
    Net::HTTP.get_print("nexusnet.herokuapp.com", "/offline")
  end


end