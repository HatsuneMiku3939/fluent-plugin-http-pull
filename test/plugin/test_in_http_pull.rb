require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'ostruct'

class HttpPullInputTest < Test::Unit::TestCase
  @stub_server = nil

  setup do
    @stub_server = StubServer.new
    @stub_server.start
  end

  teardown do
    @stub_server.shutdown
  end

  sub_test_case "default value of each options" do
    TEST_DEFAULT_VALUE_CONFIG = %[
      tag test
      url http://127.0.0.1:3939

      interval 3s
      format json
    ]

    test 'status_only' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(false, d.instance.status_only)
    end

    test 'timeout' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(10, d.instance.timeout)
    end

    test 'user' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(nil, d.instance.user)
    end

    test 'password' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(nil, d.instance.password)
    end

    test 'proxy' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(nil, d.instance.proxy)
    end
  end

  sub_test_case "success case" do
    TEST_INTERVAL_3_CONFIG = %[
      tag test
      url http://127.0.0.1:3939

      interval 3s
      format none
      status_only true
    ]

    TEST_INTERVAL_5_CONFIG = %[
      tag test
      url http://127.0.0.1:3939

      interval 5s
      format json
    ]

    TEST_INTERVAL_3_REDIRECT_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/redirect

      interval 3s
      format json
    ]

    test 'interval 3 with status_only' do
      d = create_driver TEST_INTERVAL_3_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939","status"=>200}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 5' do
      d = create_driver TEST_INTERVAL_5_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(5, d.instance.interval)

      d.run(timeout: 12) do
        sleep 11
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 3 with redirect' do
      d = create_driver TEST_INTERVAL_3_REDIRECT_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939/redirect","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end
  end

  sub_test_case "fail when not 200 OK" do
    TEST_404_INTERVAL_3_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/not_exist

      interval 3s
      format none
      status_only true
    ]

    TEST_500_INTERVAL_3_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/internal_error

      interval 3s
      format none
      status_only true
    ]

    test '404' do
      d = create_driver TEST_404_INTERVAL_3_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("http://127.0.0.1:3939/not_exist", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(404, record["status"])
        assert_not_nil(record["error"])
      end
    end

    test '500' do
      d = create_driver TEST_500_INTERVAL_3_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("http://127.0.0.1:3939/internal_error", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(500, record["status"])
        assert_not_nil(record["error"])
      end
    end
  end

  sub_test_case "fail when remote down" do
    TEST_REFUSED_CONFIG = %[
      tag test
      url http://127.0.0.1:5927
      interval 1s

      format json
    ]
    test "connection refused by remote" do
      d = create_driver TEST_REFUSED_CONFIG
      assert_equal("test", d.instance.tag)

      d.run(timeout: 4) do
        sleep 3
      end

      assert_equal(3, d.events.size)
      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("http://127.0.0.1:5927", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(0, record["status"])
        assert_not_nil(record["error"])
      end
    end
  end

  sub_test_case "fail when remote timeout" do
    TEST_TIMEOUT_FAIL_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/timeout
      timeout 2s

      interval 3s
      format json
    ]

    test "timeout" do
      d = create_driver TEST_TIMEOUT_FAIL_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(2, d.instance.timeout)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("http://127.0.0.1:3939/timeout", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(0, record["status"])
        assert_not_nil(record["error"])
      end
    end
  end

  sub_test_case "remote is prtected by basic auth" do
    TEST_AUTH_SUCCESS_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/protected
      timeout 2s
      user HatsuneMiku
      password 3939

      interval 3s
      format json
    ]

    TEST_AUTH_FAIL_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/protected
      timeout 2s
      user HatsuneMiku
      password wrong_password

      interval 3s
      format json
    ]

    TEST_AUTH_FAIL_NOT_GIVEN_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/protected
      timeout 2s

      interval 3s
      format json
    ]

    test 'interval 3 with corrent password' do
      d = create_driver TEST_AUTH_SUCCESS_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939/protected","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 3 with wrong password' do
      d = create_driver TEST_AUTH_FAIL_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("http://127.0.0.1:3939/protected", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(401, record["status"])
        assert_not_nil(record["error"])
      end
    end

    test 'interval 3 without auth info' do
      d = create_driver TEST_AUTH_FAIL_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("http://127.0.0.1:3939/protected", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(401, record["status"])
        assert_not_nil(record["error"])
      end
    end
  end

  sub_test_case "success case behind proxy" do
    TEST_INTERVAL_3_PROXY_CONFIG = %[
      tag test
      url http://127.0.0.1:3939
      proxy http://127.0.0.1:4040

      interval 3s
      format none
      status_only true
    ]

    TEST_INTERVAL_3_REDIRECT_PROXY_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/redirect
      proxy http://127.0.0.1:4040

      interval 3s
      format json
    ]

    TEST_AUTH_SUCCESS_PROXY_CONFIG = %[
      tag test
      url http://127.0.0.1:3939/protected
      proxy http://127.0.0.1:4040
      timeout 2s
      user HatsuneMiku
      password 3939

      interval 3s
      format json
    ]

    setup do
      @proxy_server = StubProxy.new
      @proxy_server.start
    end

    teardown do
      @proxy_server.shutdown
    end

    test 'interval 3 with status_only' do
      d = create_driver TEST_INTERVAL_3_PROXY_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939","status"=>200}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 3 with redirect' do
      d = create_driver TEST_INTERVAL_3_REDIRECT_PROXY_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939/redirect","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 3 with corrent password' do
      d = create_driver TEST_AUTH_SUCCESS_PROXY_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1:3939/protected","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end
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
