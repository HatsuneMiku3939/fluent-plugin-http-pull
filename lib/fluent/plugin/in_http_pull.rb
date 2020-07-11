#
# Copyright 2017- filepang
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/log"
require "fluent/plugin/input"
require "rest-client"

module Fluent
  module Plugin
    class HttpPullInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("http_pull", self)
      helpers :timer, :parser, :compat_parameters

      def initialize
        super
      end

      # basic options
      desc 'The tag of the event.'
      config_param :tag, :string

      desc 'The url of monitoring target'
      config_param :url, :string

      desc 'The path of monitoring target'
      config_param :path, :string, default: nil

      desc 'Payload to query target'
      config_param :payload, :hash, default: nil

      desc 'Message key'
      config_param :event_key, :string, default: nil

      desc 'Response contains multiple events'
      config_param :multi_event, :bool, default: false

      desc 'The interval time between periodic request'
      config_param :interval, :time

      desc 'The user agent string of request'
      config_param :agent, :string, default: "fluent-plugin-http-pull"

      desc 'status_only'
      config_param :status_only, :bool, default: false

      desc 'The http method for each request'
      config_param :http_method, :enum, list: [:get, :post, :delete], default: :get

      desc 'The timeout second of each request'
      config_param :timeout, :time, default: 10

      # proxy options
      desc 'The HTTP proxy URL to use for each requests'
      config_param :proxy, :string, default: nil

      # basic auth options
      desc 'user of basic auth'
      config_param :user, :string, default: nil

      desc 'password of basic auth'
      config_param :password, :string, default: nil, secret: true

      # login session
      desc 'login path'
      config_param :login_path, :string, default: nil

      desc 'login payload'
      config_param :login_payload, :hash, default: nil

      # req/res header options
      config_section :response_header, param_name: :response_headers, multi: true do
        desc 'The name of header to cature from response'
        config_param :header, :string
      end

      config_section :request_header, param_name: :request_headers, multi: true do
        desc 'The name of request header'
        config_param :header, :string

        desc 'The value of request header'
        config_param :value, :string
      end

      # ssl options
      desc 'verify_ssl'
      config_param :verify_ssl, :bool, default: true

      desc "The absolute path of directory where ca_file stored"
      config_param :ca_path, :string, default: nil

      desc "The absolute path of ca_file"
      config_param :ca_file, :string, default: nil


      def configure(conf)
        compat_parameters_convert(conf, :parser)
        super

        if (@login_path && !@login_payload ) || (!@login_path && @login_payload)
          raise Fluent::ConfigError, "login_path and login_payload should be both set or unset"
        end
        @parser = parser_create unless @status_only
        @_request_headers = {
          "Content-Type" => "application/x-www-form-urlencoded",
          "User-Agent" => @agent
        }.merge(@request_headers.map do |section|
          header = section["header"]
          value = section["value"]

          [header.to_sym, value]
        end.to_h)

        @http_method = :head if @status_only
      end

      def start
        super

        timer_execute(:in_http_pull, @interval, &method(:on_timer))
      end

      def on_timer
        body = nil
        record = nil
        record_time = Engine.now
        emit_stream = Fluent::MultiEventStream.new
        site = RestClient::Resource.new(@url, request_options)

        begin
          cookies = get_session_cookie(site)

          site = site[@path] if @path
          if @payload
            res = site.method(@http_method).call(@payload.to_json, :cookies=>cookies)
          else
            res = site.method(@http_method).call(:cookie=>cookies)
          end

          record, body = get_record(res, site.url)
          process_events(record, body, emit_stream)
        rescue StandardError => err
          record = { "url" => site.url, "error" => err.message }
          if err.respond_to? :http_code
            record["status"] = err.http_code || 0
          else
            record["status"] = 0
          end
          log.error(record)
          emit_stream.add(record_time, record)
        end

        router.emit_stream(@tag, emit_stream)
      end

      def shutdown
        super
      end

      private
      def request_options
        options = { timeout: @timeout, headers: @_request_headers }

        options[:proxy] = @proxy if @proxy
        options[:user] = @user if @user
        options[:password] = @password if @password

        options[:verify_ssl] = @verify_ssl
        if @verify_ssl and @ca_path and @ca_file
          options[:ssl_ca_path] = @ca_path
          options[:ssl_ca_file] = @ca_file
        end

        return options
      end

      def get_session_cookie(resource)
        cookies = {}
        return cookies unless @login_path and @login_payload

        login_response = resource[@login_path].post(@login_payload.to_json)
        if login_response.code != 200
          raise RestClient::ExceptionWithResponse.new(nil, login_response.code)
        else
          cookies = login_response.cookie_jar
        end

        return cookies
      end

      def get_record(response, url)
        body = response.body
        record = { "url" => url, "status" => response.code }
        record["header"] = {} unless @response_headers.empty?
        @response_headers.each do |section|
          name = section["header"]
          symbolize_name = name.downcase.gsub(/-/, '_').to_sym

          record["header"][name] = response.headers[symbolize_name]
        end
        return record, body
      end

      def process_events(record, body, es)

        return es.add(Engine.now, record) if @status_only or body == nil

        # consume errors produced by parser by logging it
        begin
          @parser.parse(body) do |time, events|

            events = events[@event_key] if @multi_event and @event_key || []

            # if @event_key not found, events will be converted to empty Array.
            log.warning("event_key '#{@event_key}' not found") if events == []

            # if each query result is a record, covert it to array.
            events = [ events ] unless @multi_event

            events.each do |event|
              item = record.dup
              item['message'] = event
              es.add(time, item)
            end
          end
        rescue StandardError => err
          log.error("Failed to process result with error: #{err}")
          log.debug("Failed to parse #{body}")
        end
      end

    end
  end
end
