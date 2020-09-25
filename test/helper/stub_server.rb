require 'webrick'
require 'webrick/https'

class DeleteService < WEBrick::HTTPServlet::AbstractServlet
  def service(req, res)
    if req.request_method != "DELETE"
      res.status = 405
    else
      res.status = 200
      res['Content-Type'] = 'application/json'
      res.body = '{ "status": "OK" }'
    end
  end
end

class StubServer
  def initialize(port=3939, ssl_enable=false)
    @port = port
    @ssl_enable = ssl_enable

    create_server

    # mount handler
    @server.mount_proc '/', &method(:ok)
    @server.mount_proc '/not_exist', &method(:not_exist)
    @server.mount_proc '/timeout', &method(:timeout)
    @server.mount_proc '/internal_error', &method(:internal_error)
    @server.mount_proc '/redirect', &method(:redirect)
    @server.mount_proc '/protected', &method(:protected)
    @server.mount_proc '/custom_header', &method(:custom_header)

    @server.mount_proc '/method_post', &method(:method_post)

    @server.mount_proc '/login', &method(:login)
    @server.mount_proc '/session_events', &method(:session_events)

    @server.mount '/method_delete', DeleteService

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


    if @ssl_enable
      ssl_basepath = File.join(File.dirname(__FILE__), ".ssl")
      @server = WEBrick::HTTPServer.new :Port => @port,
        :SSLEnable => true,
        :Logger => @log, :AccessLog => @access_log,
        :SSLPrivateKey => OpenSSL::PKey::RSA.new(File.open(File.join(ssl_basepath, "server.key")).read),
        :SSLCertificate => OpenSSL::X509::Certificate.new(File.open(File.join(ssl_basepath, "server.crt")).read),
        :SSLCertName => [["CN", "localhost"]]
    else
      @server = WEBrick::HTTPServer.new :Port => @port,
        :Logger => @log, :AccessLog => @access_log
    end
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

  def custom_header(req, res)
    res.header["HATSUNE-MIKU"] = req["HATSUNE-MIKU"] if req["HATSUNE-MIKU"]

    res.status = 200
    res['Content-Type'] = 'application/json'
    res.body = '{ "status": "OK" }'
  end

  def method_post(req, res)
    if req.request_method != "POST"
      res.status = 405
    else
      res.status = 200
      res['Content-Type'] = 'application/json'
      res.body = '{ "status": "OK" }'
    end
  end

  def login(req, res)
    if req.body and JSON.parse(req.body) == {"username"=>"admin", "password"=>"pwd"}
      res.status = 200
      res['Content-Type'] = 'application/json'
      res.cookies.push WEBrick::Cookie.new("session", "1")
    else
      res.status = 401
    end
  end

  def session_events(req, res)
      res.status = 200
      res['Content-Type'] = 'application/json'
      res.body = '{"ListMeta":{},"items":[{"kind":"Event","meta":{"name":"1","uuid":"c51d9e82"}},{"kind":"Event","meta":{"name":"2","uuid":"b1b5686d"}}]}'
  end

end
