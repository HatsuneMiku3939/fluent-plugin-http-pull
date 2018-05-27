require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'ostruct'

class HttpPullInputTestRequestMethod < Test::Unit::TestCase
  @stub_server = nil

  setup do
    @stub_server = StubServer.new
    @stub_server.start
  end

  teardown do
    @stub_server.shutdown
  end

  sub_test_case "request method" do
    TEST_INTERVAL_3_POST = %[
      tag test
      url http://localhost:3939/method_post

      interval 3s
      format json
      http_method post
    ]

    TEST_INTERVAL_3_DELETE = %[
      tag test
      url http://localhost:3939/method_delete

      interval 3s
      format json
      http_method delete
    ]

    test 'interval 3 with :post' do
      d = create_driver TEST_INTERVAL_3_POST
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://localhost:3939/method_post","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 3 with :delete' do
      d = create_driver TEST_INTERVAL_3_DELETE
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"http://localhost:3939/method_delete","status"=>200, "message"=>{"status"=>"OK"}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
