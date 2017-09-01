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

      desc 'The tag of the event.'
      config_param :tag, :string
      desc 'The url of monitoring target'
      config_param :url, :string
      desc 'The interval time between periodic request'
      config_param :interval, :time
      desc 'status_only'
      config_param :status_only, :bool, default: false
      desc 'timeout second of each request'
      config_param :timeout, :time, default: 10

      desc 'user of basic auth'
      config_param :user, :string, default: nil
      desc 'password of basic auth'
      config_param :password, :string, default: nil

      def configure(conf)
        compat_parameters_convert(conf, :parser)
        super

        @parser = parser_create unless @status_only
      end

      def start
        super

        timer_execute(:in_http_pull, @interval, &method(:on_timer))
      end

      def on_timer
        record = { "url" => @url }

        begin
          res = RestClient::Request.execute(method: :get,
                                            url: @url,
                                            timeout: @timeout,
                                            user: @user, password: @password)
          record["status"] = res.code
          record["body"] = res.body
        rescue StandardError => err
          if err.respond_to? :http_code
            record["status"] = err.http_code || 0
          else
            record["status"] = 0
          end

          record["error"] = err.message
        end

        record_time = Engine.now

        if !@status_only && record["body"] != nil
          @parser.parse(record["body"]) do |time, message|
            record["message"] = message
            record_time = time
          end
        end

        record.delete("body")
        router.emit(@tag, record_time, record)
      end

      def shutdown
        super
      end

    end
  end
end
