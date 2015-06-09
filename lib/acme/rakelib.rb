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
  # Some snazy utility methods for better Assignment Branch Condition
  # Cyclomatic complexity Perceived.
  #
  module Rakelib
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

    def startup_core
      ['squid', 'router', 'consul'].each do |container|
        c = instance_eval "ACME.#{container}"
        printf "%-70s %-s\n",
          "Starting container #{c.name}:",
          "[#{c.ip.yellow}]"
        c.created? ? c.started? ? c.run : c.start.run : c.create.start.run
      end
    end

    def startup_elkstack
      ['logstash', 'elasticsearch', 'kibana'].each do |container|
        c = instance_eval "ACME.#{container}"
        c.created? ? c.started? ? c.run : c.start.run : c.create.start.run
        if c.fqdn
          printf "%-70s %-s\n",
            "Starting container #{c.fqdn}:",
            "[#{c.ip.yellow}]"
        else
          printf "%-70s %-s\n", "Starting container #{c.name}:", "[#{ret_ok}]"
        end
      end
    end

    def startup_chefstack
      ['chef', 'jenkins', 'slave'].each do |container|
        c = instance_eval "ACME.#{container}"
        c.created? ? c.started? ? c.run : c.start.run : c.create.start.run
        printf "%-70s %-s\n",
          "Starting container #{c.fqdn}:",
          "[#{c.ip.yellow}]"
      end
    end

    def timer(wait)
      puts "\nWaiting for Chef server to auto configure:\n".red
      progress_bar wait
      puts
      ACME.chef.extend(ACME::Extensions::ChefServer)
    end

    def chef_bootstrap(user, org, git, chef_server)
      unless ACME.chef.user_list.include? user[:name]
        printf "%-70s %-s\n",
          "Creating Chef user #{user[:name]}:",
          "[#{ret_ok}]"
        client_key = ACME.chef.create_user(user)

        printf "%-70s %-s\n",
          "Creating Chef org #{org[:name]}:",
          "[#{ret_ok}]"
        validation_key = ACME.chef.create_org(org)

        printf "%-70s %-s\n",
          "Creating data bags for '#{org[:name]}' org:",
          "[#{ret_ok}]"
        ACME.chef.render_data_bag(org[:name], client_key, validation_key)

        printf "%-70s %-s\n",
          "Creating knife config for '#{org[:name]}' org:",
          "[#{ret_ok}]"
        ACME.chef.render_knife
      end

      printf "%-70s %-s\n", "Fetching server SSL certificates:", "[#{ret_warn}]"
      system 'knife ssl fetch'
      puts "\nBerkshelf install && upload:".blue
      system 'berks install -c .berkshelf/config.json'
      system 'berks upload  -c .berkshelf/config.json'
      puts "\nUploading environments:".blue
      system 'knife environment from file environments/*'
      puts "\nUploading roles:".blue
      system 'knife role from file roles/*'
      puts "\nUploading and uploading data bags:".blue
      system 'knife data bag create chef_org'
      system 'knife data bag create users'
      system 'knife data bag from file chef_org data_bag/chef_org/*'
      system 'knife data bag from file users data_bag/users/*'
      system 'knife cookbook upload pipeline --freeze --force'
      puts "\nChef Server bootstrapping complete!\n".green
    end
  end
end
