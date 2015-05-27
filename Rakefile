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

require_relative 'lib/acme'
include ACME

BASEDIR = File.dirname(__FILE__)

def o
  {
    org:         'acme',
    long_name:   'ACME Auto Parts & Plumbing Co.',
    user:        'jenkins',
    full_name:   'Mr. Jenkins',
    email:       'jenkins@acme.dev',
    passwd:      'password',
    chef_server: 'https://chef-server.acme.dev/',
    git_url:     'https://github.com/riddopic/thrashmaster.git',
    branch:      '*/master',
    polling:     '* * * * *'
  }
end




desc 'Start a full pipeline stack'
task :start do
  amount = ACME::exists?('chef-server') ? 3 : 160

  puts "\nACME Auto Parts & Plumbing Corporation, Inc.\n".blue
  puts 'Welcome to ACME Auto Parts & Plumbing, a Wholly-Owned Subsidiary of'
  puts 'ACME Bait & Tackle Corporation where quality is our #1 dream! This is'
  puts 'the ACME operations repository of development cooking and pipe laying,'
  puts 'continuously for delivery, please enjoy the tour.'
  puts "\nStarting Pipeline Stack".yellow
  Utils::mark_line
  ACME::docker_kernel

  ACME::containers.each do |container|
    unless container.created?
      container.do(:create).do(:start).do(:run_sshd)

      printf "%-60s %10s\n",
             "Starting container #{container.fqdn.red}:",
             "[#{container.ip.yellow}]"
      # Give the Consul node time to get an IP.
      sleep 2 if container.name == 'consul'
    end
  end

  puts "\nWaiting for Chef server to auto configure:\n".orange
  Utils::progress_bar amount
  ACME::create_chef_user o[:user], o[:full_name], o[:email], o[:passwd], o[:org]
  ACME::create_chef_org  o[:org],  o[:long_name], o[:user]
  ACME::render_data_bag  o[:org]
  ACME::render_knife

  system 'knife ssl fetch'
  system 'berks install -c .berkshelf/config.json'
  system 'berks upload -c .berkshelf/config.json'
  system 'knife environment from file environments/*'
  system 'knife role from file roles/*'
  system 'knife data bag create chef_org'
  system 'knife data bag create users'
  system 'knife data bag from file chef_org data_bag/chef_org/*'
  system 'knife data bag from file users data_bag/users/*'
  system 'knife cookbook upload pipeline --freeze --force'

  # containers.each do |container|
  ACME::containers.each do |container|
    Utils::mark_line
    printf "%-60s %10s\n",
           "\nBootstraping container #{container.fqdn.red}:", ''
    container.do(:bootstrap)
  end
end

desc 'Do the Chef'
task :chef do
  ACME::containers.each do |container|
    Utils::mark_line
    printf "%-60s %10s\n",
           "\nExecuting chef-client on container #{container.fqdn.red}:", ''
    container.chef_client
  end
end

desc 'Stop and cleanup pipeline stack'
task :clean do
  ACME::containers.each do |c|
    Utils::mark_line
    printf "%-60s %10s\n",
           "\nStoping and cleaning up container #{c.fqdn.red}:", ''
    c.created? ? c.running? ? c.stop.delete : c.delete : false
  end
end

task :silly do
  puts "\nACME Auto Parts & Plumbing Corporation, Inc.\n".blue
  puts 'Welcome to ACME Auto Parts & Plumbing, a Wholly-Owned Subsidiary of'
  puts 'ACME Bait & Tackle Corporation where quality is our #1 dream! This is'
  puts 'the ACME operations repository of development cooking and pipe laying,'
  puts 'continuously for delivery, please enjoy the tour.'
  puts "\nStarting Pipeline Stack".yellow
  Utils::mark_line
  require 'pry'
  binding.pry
end

