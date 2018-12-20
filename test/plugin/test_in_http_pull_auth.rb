require 'helper'
require 'fluent/plugin/in_http_pull.rb'

require 'ostruct'

class HttpPullInputTestAuth < Test::Unit::TestCase
  @stub_server = nil

  setup do
    @stub_server = StubServer.new
    @stub_server.start
  end

  teardown do
    @stub_server.shutdown
  end

  sub_test_case 'remote is prtected by basic auth' do
    TEST_AUTH_SUCCESS_CONFIG = %[
      tag test
      url http://localhost:3939/protected
      timeout 2s
      user HatsuneMiku
      password 3939

      interval 3s
      format json
    ]

    TEST_AUTH_FAIL_CONFIG = %[
      tag test
      url http://localhost:3939/protected
      timeout 2s
      user HatsuneMiku
      password wrong_password

      interval 3s
      format json
    ]

    TEST_AUTH_FAIL_NOT_GIVEN_CONFIG = %[
      tag test
      url http://localhost:3939/protected
      timeout 2s

      interval 3s
      format json
    ]

    test 'interval 3 with corrent password' do
      d = create_driver TEST_AUTH_SUCCESS_CONFIG
      assert_equal('test', d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal('test', tag)

        assert_equal({'url'=>'http://localhost:3939/protected','status'=>200, 'message'=>{'status'=>'OK'}}, record)
        assert(time.is_a?(Fluent::EventTime))
      end
    end

    test 'interval 3 with wrong password' do
      d = create_driver TEST_AUTH_FAIL_CONFIG
      assert_equal('test', d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal('test', tag)

        assert_equal('http://localhost:3939/protected', record['url'])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(401, record['status'])
        assert_not_nil(record['error'])
      end
    end

    test 'interval 3 without auth info' do
      d = create_driver TEST_AUTH_FAIL_CONFIG
      assert_equal('test', d.instance.tag)
      assert_equal(3, d.instance.interval)

      d.run(timeout: 8) do
        sleep 7
      end
      assert_equal(2, d.events.size)

      d.events.each do |tag, time, record|
        assert_equal('test', tag)

        assert_equal('http://localhost:3939/protected', record['url'])
        assert(time.is_a?(Fluent::EventTime))

        assert_equal(401, record['status'])
        assert_not_nil(record['error'])
      end
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
