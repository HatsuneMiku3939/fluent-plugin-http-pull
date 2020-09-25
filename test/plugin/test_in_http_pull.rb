require "helper"
require "fluent/plugin/in_http_pull"

require 'ostruct'

class HttpPullInputTestDefaultOptions < Test::Unit::TestCase
  sub_test_case "default value of each options" do
    TEST_DEFAULT_VALUE_CONFIG = %[
      tag test
      url http://localhost:3939

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

    test 'http_method' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(:get, d.instance.http_method)
    end

    test 'agent' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal("fluent-plugin-http-pull", d.instance.agent)
    end

    test 'verify_ssl' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(true, d.instance.verify_ssl)
    end

    test 'ca_path' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(nil, d.instance.ca_path)
    end

    test 'ca_file' do
      d = create_driver TEST_DEFAULT_VALUE_CONFIG
      assert_equal("test", d.instance.tag)

      assert_equal(nil, d.instance.ca_file)
    end
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::HttpPullInput).configure(conf)
  end
end
