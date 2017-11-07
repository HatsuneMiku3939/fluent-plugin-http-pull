require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'ostruct'

class HttpPullInputTestHttpHeader < Test::Unit::TestCase
  @stub_server = nil

  setup do
    @stub_server = StubServer.new
    @stub_server.start
  end

  teardown do
    @stub_server.shutdown
  end

  sub_test_case "capture response header" do
    TEST_INTERVAL_3_RES_HEADER_CONFIG = %[
      tag test
      url http://127.0.0.1:3939

      interval 3s
      format json

      <response_header>
        header Content-Type
      </response_header>
    ]

    TEST_INTERVAL_3_RES_MULTI_HEADER_CONFIG = %[
      tag test
      url http://127.0.0.1:3939

      interval 3s
      format json

      <response_header>
        header Content-Type
      </response_header>

      <response_header>
        header Content-Length
      </response_header>
    ]

    test 'interval 3 with single header' do
      d = create_driver TEST_INTERVAL_3_RES_HEADER_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939","status"=>200,"message"=>{"status"=>"OK"},"header"=>{"Content-Type"=>"application/json"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 3 with multiple header' do
      d = create_driver TEST_INTERVAL_3_RES_MULTI_HEADER_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939","status"=>200,"message"=>{"status"=>"OK"},"header"=>{"Content-Type"=>"application/json","Content-Length"=>"18"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end
  end

  sub_test_case "custom request header" do
    TEST_INTERVAL_3_CUSTOM_HEADER_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/custom_header

      interval 3s
      format json

      <request_header>
        header HATSUNE-MIKU
        value 3939
      </request_header>

      <response_header>
        header HATSUNE-MIKU
      </response_header>
    ]

    test 'interval 3 with single header' do
      d = create_driver TEST_INTERVAL_3_CUSTOM_HEADER_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939/custom_header","status"=>200,"message"=>{"status"=>"OK"},"header"=>{"HATSUNE-MIKU"=>"3939"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
