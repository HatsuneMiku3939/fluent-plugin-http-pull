require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'ostruct'

class HttpPullInputTest < Test::Unit::TestCase
  TEST_INTERVAL_3_CONFIG = %[
    tag test
    url http://127.0.0.1

    interval 3
    status_only true
  ]

  TEST_INTERVAL_5_CONFIG = %[
    tag test
    url http://127.0.0.1

    interval 5
  ]

  setup do
    Fluent::Test.setup
  end

  sub_test_case "success case with status only" do
    setup do
      mock(RestClient).get("http://127.0.0.1").times(2) do
        OpenStruct.new({code: 200, body: '{"status": "OK"}'})
      end
    end

    test 'interval 3 with status_only' do
      d = create_driver TEST_INTERVAL_3_CONFIG
      assert_equal "test", d.instance.tag

      d.run(timeout: 5) do
        sleep 5
      end
      assert_equal 2, d.events.size

      d.events.each do |tag, time, record|
        assert_equal("test", tag)
        assert_equal({"url"=>"http://127.0.0.1","status"=>200}, record)
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
        assert_equal({"url"=>"http://127.0.0.1","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
