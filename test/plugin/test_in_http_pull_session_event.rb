require "helper"
require "fluent/plugin/in_http_pull.rb"

require 'ostruct'

class HttpPullInputTestMultiEvent < Test::Unit::TestCase
  @stub_server = nil

  setup do
    @stub_server = StubServer.new
    @stub_server.start
  end

  teardown do
    @stub_server.shutdown
  end

  sub_test_case "multi event" do
    TEST_NO_LOGIN_PAYLOAD = %[
      tag test
      url http://localhost:3939
      path session_events
      event_key items
      multi_event true

      login_path login

      interval 3s
      format json
      http_method post
    ]

    TEST_LOGIN_FAILURE = %[
      tag   test
      url   http://localhost:3939
      path  session_events
      event_key items
      multi_event true

      login_path login
      login_payload {"username": "admin","password": "wrong"}

      interval 3s
      format json
      http_method post
    ]
    TEST_LOGIN_MULTI_EVENT = %[
      tag   test
      url   http://localhost:3939
      path  session_events
      event_key items
      multi_event true

      login_path login
      login_payload {"username": "admin","password": "pwd"}
 
      interval 3s
      format json
      http_method post
    ]

    test 'login failed no login payload' do

      assert_raise do
        create_driver TEST_NO_LOGIN_PAYLOAD
      end
    end

    test 'login failed wrong credential' do

      d = create_driver TEST_LOGIN_FAILURE
      d.run(timeout: 5) do
        sleep 4
      end
      assert_equal(1, d.events.length)
      d.events.each do |tag, time, record|
         assert_equal(401, record['status'])
      end
    end
    
    test 'session multi events' do
      d = create_driver TEST_LOGIN_MULTI_EVENT
      d.run(timeout: 5) do
        sleep 4
      end

      assert_equal(2, d.events.length)

      uuids = []
      d.events.each do |tag, time, record|
        uuids.push(record['message']['meta']['uuid'])
      end
      assert_equal(["c51d9e82","b1b5686d"], uuids)
    end

  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
