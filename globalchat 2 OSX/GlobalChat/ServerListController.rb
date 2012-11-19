require 'net/http'

class ServerListController

  attr_accessor :server_list_hash, :names, :server_list_table, :server_list_window, :gcc, :chat_window, :host, :port, :password, :handle

  def initialize
    get_servers
  end

  def get_servers
    @server_list_hash = Net::HTTP.get('nexusnet.herokuapp.com', '/msl').
    split("\n").
    collect do |s|
      par = s.split("-!!!-")
      {:host => par[1], :name => par[0], :port => par[2]}
    end

    @names = @server_list_hash.map { |i| i[:name] }

  end

  def tableView(view, objectValueForTableColumn:column, row:index)
    @names.nil? ? 0 : @names[index]
  end

  def numberOfRowsInTableView(view)
    @names.nil? ? 0 : @names.size
  end


  def refresh(sender)
    get_servers
    @server_list_table.reloadData
  end

  def changeInfo(sender)
    @host.setStringValue @server_list_hash[sender.selectedRow][:host]
    @port.setStringValue @server_list_hash[sender.selectedRow][:port]
  end

  def connect(sender)
    # save defaults
    $prefs.setObject(@host.stringValue, :forKey => "host")
    $prefs.setObject(@handle.stringValue, :forKey => "handle")
    $prefs.setObject(@port.stringValue, :forKey => "port")

    @gcc.handle = @handle.stringValue
    @gcc.host = @host.stringValue
    @gcc.port = @port.stringValue
    @gcc.password = @password.stringValue
    @gcc.nicks = []
    @gcc.chat_buffer = ""

    unless @gcc.sign_on
      @gcc.autoreconnect
    end

  end


end
