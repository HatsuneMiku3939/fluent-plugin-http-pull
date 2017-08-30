require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'ostruct'

class HttpPullInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  sub_test_case "default value of each options" do
    TEST_DEFAULT_VALUE_CONFIG = %[
      tag test
      url http://127.0.0.1

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
  end

  sub_test_case "success case with status only" do
    TEST_INTERVAL_3_CONFIG = %[
      tag test
      url http://127.0.0.1
      timeout 10

      interval 3s
      format none
      status_only true
    ]

    TEST_INTERVAL_5_CONFIG = %[
      tag test
      url http://127.0.0.1
      timeout 10

      interval 5s
      format json
    ]

    setup do
      mock(RestClient::Request).
        execute(method: :get,
                url: "http://127.0.0.1",
                timeout: 10).
        times(2) do
          OpenStruct.new({code: 200, body: '{"status": "OK"}'})
        end
    end

    test 'interval 3 with status_only' do
      d = create_driver TEST_INTERVAL_3_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 5) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1","status"=>200}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 5' do
      d = create_driver TEST_INTERVAL_5_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(5, d.instance.interval)

      d.run(timeout: 7) do
        sleep 11
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://127.0.0.1","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
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

      d.run(timeout: 2) do
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
      url http://127.0.0.1
      timeout 2s

      interval 3s
      format json
    ]

    setup do
      mock(RestClient::Request).
        execute(method: :get,
                url: "http://127.0.0.1",
                timeout: 2).
        times(2) do
          sleep 2
          raise RestClient::Exceptions::Timeout.new
        end
    end

    test "timeout" do
      d = create_driver TEST_TIMEOUT_FAIL_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(2, d.instance.timeout)

      d.run(timeout: 5) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("http://127.0.0.1", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(0, record["status"])
        assert_not_nil(record["error"])
      end
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
