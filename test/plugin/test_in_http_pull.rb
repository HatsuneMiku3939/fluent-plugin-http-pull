require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'webrick'

class HttpPullInputTest < Test::Unit::TestCase
  PORT = rand(1000) + 3000
  TEST_INTERVAL_3_CONFIG = %[
    tag test
    url http://127.0.0.1:#{PORT}

    interval 3
    status_only true
  ]

  TEST_INTERVAL_5_CONFIG = %[
    tag test
    url http://127.0.0.1:#{PORT}

    interval 5
  ]

  @test_server = nil

  setup do
    Fluent::Test.setup

    Thread.new do
      @test_server = WEBrick::HTTPServer.new :Port => PORT
      @test_server.mount_proc '/' do |req, res|
        res.status = 200
        res['Content-Type'] = 'application/json'
        res.body = '{"status":"OK"}'
      end
      @test_server.start
    end
  end

  teardown do
    @test_server.shutdown
    sleep 1
  end

  test 'interval 3 with status_only' do
    d = create_driver TEST_INTERVAL_3_CONFIG
    assert_equal "test", d.instance.tag

    d.run(timeout: 8) do
      sleep 8
    end
    assert_equal 3, d.events.size

    d.events.each do |tag, time, record|
      assert_equal("test", tag)
      assert_equal({"url"=>"http://127.0.0.1:#{PORT}","status"=>200}, record)
      assert(time.is_a?(Fluent::EventTime))
    end
  end

  test 'interval 5' do
    d = create_driver TEST_INTERVAL_5_CONFIG
    assert_equal "test", d.instance.tag

    d.run(timeout: 7) do
      sleep 7
    end
    assert_equal 2, d.events.size

    d.events.each do |tag, time, record|
      assert_equal("test", tag)
      assert_equal({"url"=>"http://127.0.0.1:#{PORT}","status"=>200, "message"=>{"status"=>"OK"}}, record)
      assert(time.is_a?(Fluent::EventTime))
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
