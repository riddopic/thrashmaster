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

module ACME
  # Class methods to help in the Rakeing of the containers.
  #
  module Extensions
    # Methods are also available as module-level methods as well as a mixin.
    extend self

    # Returns a list of all containers from the endpoint.
    #
    # @param [Boolean] all
    #   When true will show all containers (started and stopped), when false
    #   only running containers are listed.
    #
    # @return [Array]
    #
    def running(all = true)
      Docker::Container.all(all: all)
    end

    # Request a Container by ID or name.
    #
    # @param [String] name
    #   The name of the container to get.
    #
    # @return [Docker::Container]
    #
    def get(name)
      Docker::Container.get(name)
    end

    # Check to see if a given container exists, it is considered to exists if
    # it has a state of restarting, running, paused, or exited.
    #
    # @param [String] name
    #   The name of the container to get.
    #
    # @return [Boolean]
    #
    def exists?(name)
      running.map { |r| r.info['Names'].include?("/#{name}") }.any?
    end

    def ret_ok
      'OK'.green
    end

    def ret_warn
      'Warning'.yellow
    end

    def ret_fail
      'Failed'.red
    end

    def docker_kernel
      puts "\nSetting Docker host SHMMAX and SHMALL kernel paramaters:"
      host = `docker-machine ip`.strip
      user = 'docker'
      keys = [File.join(ENV['DOCKER_CERT_PATH'], 'id_rsa')]
      ['sudo sysctl -w kernel.shmmax=17179869184',
       'sudo sysctl -w kernel.shmall=4194304'
      ].each do |cmd|
        resp = Net::SSH.start(host, user, keys: keys) { |ssh| ssh.exec!(cmd) }
        printf "%1s %22s %-12s\n", '', "[#{resp.strip.yellow}]", ''
      end
    end
  end
end
