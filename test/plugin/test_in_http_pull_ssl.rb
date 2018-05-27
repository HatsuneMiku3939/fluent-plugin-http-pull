require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'ostruct'

class HttpPullInputTestSSLBasic < Test::Unit::TestCase
  @stub_server = nil

  setup do
    @stub_server = StubServer.new(4040, true)
    @stub_server.start
  end

  teardown do
    @stub_server.shutdown
  end

  sub_test_case "remote has valid ssl cert" do
    TEST_INTERVAL_3_VALID_SSL_CONFIG = %[
      tag test
      url https://www.google.com

      interval 3s
      format none
      status_only true
    ]

    # test 'interval 3' do
    #   d = create_driver TEST_INTERVAL_3_VALID_SSL_CONFIG
    #   assert_equal("test", d.instance.tag)
    #   assert_equal(3, d.instance.interval)

    #   d.run(timeout: 8) do
    #     sleep 7
    #   end
    #   assert_equal(2, d.events.size)

    #   d.events.each do |tag, time, record|
    #     assert_equal("test", tag)

    #     assert_equal({"url"=>"https://www.google.com","status"=>200}, record)
    #     assert(time.is_a?(Fluent::EventTime))
    #   end
    # end
  end

  sub_test_case "remote has self-signed ssl cert" do
    TEST_INTERVAL_3_CONFIG = %[
      tag test
      url https://localhost:4040

      interval 3s
      format none
      status_only true
    ]

    TEST_INTERVAL_3_VERIFY_FALSE_CONFIG = %[
      tag test
      url https://localhost:4040

      interval 3s
      format none
      status_only true
      verify_ssl false
    ]

    TEST_INTERVAL_3_CA_CONFIG = %[
      tag test
      url https://localhost:4040

      interval 3s
      format none
      status_only true
      ca_path #{Dir.pwd}/test/helper/.ssl
      ca_file #{Dir.pwd}/test/helper/.ssl/server.crt
    ]

    TEST_INTERVAL_3_INVALID_CA_CONFIG = %[
      tag test
      url https://localhost:4040

      interval 3s
      format none
      status_only true
      ca_path #{Dir.pwd}/test/helper/.ssl_not_exist
      ca_file #{Dir.pwd}/test/helper/.ssl_not_exist/server.crt
    ]

    test 'should be fail with no ssl options' do
      d = create_driver TEST_INTERVAL_3_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("https://localhost:4040", record["url"])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(0, record["status"])
        assert_not_nil(record["error"])
      end
    end

    test 'should be success with verify_ssl false' do
      d = create_driver TEST_INTERVAL_3_VERIFY_FALSE_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"https://localhost:4040","status"=>200}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'should be success with valid ca options' do
      d = create_driver TEST_INTERVAL_3_CA_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal({"url"=>"https://localhost:4040","status"=>200}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'should be fail with invalid ca options' do
      d = create_driver TEST_INTERVAL_3_INVALID_CA_CONFIG
      assert_equal("test", d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal("test", tag)

        assert_equal("https://localhost:4040", record["url"])
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
