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

      desc 'The tag of the event.'
      config_param :tag, :string

      desc 'The uri of monitoring target'
      config_param :url, :string

      desc 'The second interval time between periodic request'
      config_param :interval, :integer

      desc 'status_only'
      config_param :status_only, :bool, default: false

      def configure(conf)
        super

        @shutdown = false
      end

      def start
        @thread = Thread.new(&method(:run))
      end

      def run
        while !@shutdown
          ts = Time.now.to_f

          log = { "url" => @url }

          begin
            res = RestClient.get(@url)
            log["status"] = res.code
            log["body"] = res.body
          rescue RestClient::ExceptionWithResponse => err
            log["status"] = err.code
            log["error"] = err.message
          rescue Exception => err
            log["status"] = 0
            log["error"] = err.message
          end

          log["message"] = JSON.parse(log["body"]) if !@status_only && log["body"] != nil
          log.delete("body")

          router.emit(@tag, Engine.now, log)

          te = Time.now.to_f
          delay = @interval - (te - ts)
          delay = delay > 0 ? delay : 0

          sleep delay
        end
      end

      def shutdown
        @shutdown = true
        @thread.join if @thread
      end

    end
  end
end
