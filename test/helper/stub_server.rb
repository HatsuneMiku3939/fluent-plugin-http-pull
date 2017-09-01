require 'webrick'

class StubServer
  def initialize
    create_server

    # mount handler
    @server.mount_proc '/', &method(:ok)
    @server.mount_proc '/not_exist', &method(:not_exist)
    @server.mount_proc '/timeout', &method(:timeout)
    @server.mount_proc '/internal_error', &method(:internal_error)
    @server.mount_proc '/redirect', &method(:redirect)
    @server.mount_proc '/protected', &method(:protected)
  end

  def start
    @thread = Thread.new { @server.start }
  end

  def shutdown
    @server.shutdown

    # wait until webrick was shutting down
    while true
      break if @thread.status == false

      # issue webrick shutdown once more
      @server.shutdown
      sleep 1
    end

    # then exit thread
    @thread.exit
  end

  private
  def create_server
    @log_file = File.open("stub_server.log", "a+")
    @log = WEBrick::Log.new @log_file
    @access_log = [
      [@log_file, WEBrick::AccessLog::COMBINED_LOG_FORMAT],
    ]

    @server = WEBrick::HTTPServer.new :Port => 3939, :Logger => @log, :AccessLog => @access_log
  end

  def ok(req, res)
    res.status = 200
    res['Content-Type'] = 'application/json'
    res.body = '{ "status": "OK" }'
  end

  def not_exist(req, res)
    res.status = 404
    res.body = ''
  end

  def timeout(req, res)
    sleep 3

    res.status = 200
    res['Content-Type'] = 'application/json'
    res.body = '{ "status": "OK" }'
  end

  def internal_error(req, res)
    res.status = 500
    res.body = ''
  end

  def redirect(req, res)
    res.set_redirect WEBrick::HTTPStatus::TemporaryRedirect, "http://127.0.0.1:3939/"
  end

  def protected(req, res)
    WEBrick::HTTPAuth.basic_auth(req, res, 'protected') do |user, password|
      user == 'HatsuneMiku' && password == '3939'
    end

    res.status = 200
    res['Content-Type'] = 'application/json'
    res.body = '{ "status": "OK" }'
  end
end
