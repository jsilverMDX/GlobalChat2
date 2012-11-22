

class AppDelegate
    attr_accessor :window, :gcsc, :server_name

    def applicationDidFinishLaunching(a_notification)
      $app = self
      $prefs = NSUserDefaults.standardUserDefaults
      @server_name.setStringValue($prefs.stringForKey("server_name") || "")
      
      # entry
      @gcsc.gchatserv = GlobalChatServer.new
      
      @gcsc.gchatserv.start
      
      @gcsc.published = false
      
      NSTimer.scheduledTimerWithTimeInterval(1,
        target:@gcsc,
        selector:"checkStatus",
        userInfo:nil,
        repeats:true)
      
    end
end

