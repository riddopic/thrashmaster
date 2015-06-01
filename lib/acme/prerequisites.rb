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

require_relative 'os'
require_relative 'utils'

module ACME
  # Sanity check the environment and attempt to validate and provide better
  # errors if nil for no explicit conversion of String to Symbol.
  #
  module Prerequisites
    include Utils

    # Methods are also available as module-level methods as well as a mixin.
    extend self

    def validate
      if OS.mac?
        check_docker
        printf "%-70s %-10s\n", 'Checking for local resolver:', "[#{resolver?}]"
        printf "%-70s %-10s\n", 'Checking for Chef DK:',        "[#{chefdk?}]"
      else
        put 'This OS has not been tested to work, good luck...'
      end
    end

    def check_docker
      printf "%-70s %-10s\n",
             'Checking for docker machine:', "[#{docker?}]"
      printf "%-70s %-10s\n",
             'Checking for docker environment variables:', "[#{docker_vars?}]"
      printf "%-70s %-10s\n",
             'Checking for docker certificates:', "[#{docker_certs?}]"
    end

    private

    def docker?
      if command_in_path?('docker') && command_in_path?('docker-machine')
        'OK'.green
      else
        'Fail!'.red
      end
    end

    def resolver?
      if '/etc/resolver/dev'.contains? "nameserver #{ACME.consul.ip}"
        'OK'.green
      else
        'Warning'.yellow
      end
    end

    def chefdk?
      if '/opt/chefdk/version-manifest.txt'.contains? 'chefdk'
        'OK'.green
      else
        'Warning'.yellow
      end
    end

    def docker_vars?
      if ENV['DOCKER_HOST'] && ENV['DOCKER_CERT_PATH']
        'OK'.green
      else
        'Warning'.yellow
      end
    end

    def docker_certs?
      pems = %w[cert.pem key.pem ca.pem]
      if pems.map { |f| File.exist?(File.join ENV['DOCKER_CERT_PATH'], f) }.all?
        'OK'.green
      else
        'Warning'.yellow
      end
    end
  end
end
