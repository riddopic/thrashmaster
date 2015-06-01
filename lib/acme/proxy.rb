# encoding: UTF-8
#
# Author:    Stefano Harding <riddopic@gmail.com>
# License:   Apache License, Version 2.0
# Copyright: (C) 2014-2015 Stefano Harding
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
#

require 'socket'

module ACME
  # Checks for a local running caching proxy to use.
  #
  module Proxy
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    def local_ip
      @local_ip ||= begin
        orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true

        UDPSocket.open do |s|
          s.connect '64.233.187.99', 1
          s.addr.last
        end
      ensure
        Socket.do_not_reverse_lookup = orig
      end
    end

    def local_port
      8123
    end

    def http_proxy_url
      "http://#{local_ip}:#{local_port}"
    end

    def env
      "HTTP_PROXY=#{http_proxy_url}"
    end

    def no_proxy
      'NO_PROXY=localhost,127.0.0.1,192.168.0.0,10.0,172.17.0.0,acme.dev'
    end

    def running?
      socket = TCPSocket.new(local_ip, local_port)
      true
    rescue SocketError, Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
      false
    rescue Errno::EPERM, Errno::ETIMEDOUT
      false
    ensure
      socket && socket.close
    end
  end
end
