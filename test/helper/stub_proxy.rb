require 'webrick'
require 'webrick/httpproxy'

class StubProxy
  def initialize
    create_proxy
  end

  def start
    @thread = Thread.new { @proxy.start }
  end

  def shutdown
    @proxy.shutdown

    # wait until webrick was shutting down
    while true
      break if @thread.status == false

      # issue webrick shutdown once more
      @proxy.shutdown
      sleep 1
    end

    # then exit thread
    @thread.exit
  end

  private
  def create_proxy
    @log_file = File.open("stub_proxy.log", "a+")
    @log = WEBrick::Log.new @log_file
    @access_log = [
      [@log_file, WEBrick::AccessLog::COMBINED_LOG_FORMAT],
    ]

    @proxy = WEBrick::HTTPProxyServer.new :Port => 4040, :Logger => @log, :AccessLog => @access_log
  end
end
