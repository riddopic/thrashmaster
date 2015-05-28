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

BASEDIR = File.dirname(__FILE__)
require_relative 'lib/acme'
extend ACME

def o
  {
    org:         'acme',
    long_name:   'ACME Auto Parts & Plumbing Co.',
    user:        'jenkins',
    full_name:   'Mr. Jenkins',
    email:       'jenkins@acme.dev',
    passwd:      'password',
    chef_server: 'chef-server.acme.dev',
    git_url:     'https://github.com/riddopic/thrashmaster.git',
    branch:      '*/master',
    polling:     '* * * * *'
  }
end

module ACME
  container 'consul' do
    fqdn    'consul.acme.dev'
    image   'acme/consul'
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'seagull' do
    fqdn    'seagull.acme.dev'
    image   'acme/seagull'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    volumes ['/var/run/docker.sock' => {}]
    binds   ['/var/run/docker.sock:/var/run/docker.sock']
  end

  container 'kibana' do
    fqdn    'kibana.acme.dev'
    image   'acme/kibana'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'logstash' do
    fqdn    'logstash.acme.dev'
    image   'acme/logstash'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'elasticsearch' do
    fqdn    'elasticsearch.acme.dev'
    image   'acme/elasticsearch'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'chef-server' do
    fqdn    'chef-server.acme.dev'
    image   'acme/chef-server'
    env     [->{ "JOIN_IP=#{join_ip}" },
             "PUBLIC_URL=#{o[:chef_server]}",
             "OC_ID_ADMINISTRATORS=#{o[:jenkins]}"]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'jenkins' do
    fqdn    'jenkins.acme.dev'
    image   'acme/centos-6'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[jenkins_master]']
  end

  container 'slave' do
    fqdn    'slave.acme.dev'
    image   'acme/docker'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[jenkins_slave]']
  end
end

desc 'Start a full pipeline stack'
task :start do
  amount = exists?('chef-server') ? 3 : 160

  puts "\nACME Auto Parts & Plumbing Corporation, Inc.\n".blue
  puts 'Welcome to ACME Auto Parts & Plumbing, a Wholly-Owned Subsidiary of'
  puts 'ACME Bait & Tackle Corporation where quality is our #1 dream! This is'
  puts 'the ACME operations repository of development cooking and pipe laying,'
  puts 'continuously for delivery, please enjoy the tour.'
  puts "\nStarting Pipeline Stack".yellow
  mark_line
  docker_kernel

  containers.each do |container|
    unless container.created?
      container.create.start.run_sshd

      printf "%-60s %10s\n",
             "Starting container #{container.fqdn.red}:",
             "[#{container.ip.yellow}]"
      # Give the Consul node time to get an IP.
      sleep 2 if container.name == 'consul'
    end
  end

  puts "\nWaiting for Chef server to auto configure:\n".orange
  progress_bar amount
  create_chef_user    o[:user], o[:full_name], o[:email], o[:passwd], o[:org]
  create_chef_org     o[:org],  o[:long_name], o[:user]
  render_data_bag     o[:org]
  render_knife

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
  containers.each do |container|
    mark_line
    printf "%-60s %10s\n",
           "\nBootstraping container #{container.fqdn.red}:", ''
    container.bootstrap
  end
end

desc 'Do the Chef'
task :chef do
  containers.each do |container|
    mark_line
    printf "%-60s %10s\n",
           "\nExecuting chef-client on container #{container.fqdn.red}:", ''
    container.chef_client
  end
end

desc 'Stop and cleanup pipeline stack'
task :clean do
  containers.each do |c|
    mark_line
    printf "%-60s %10s\n",
           "\nStoping and cleaning up container #{c.fqdn.red}:", ''
    c.created? ? c.running? ? c.stop.delete : c.delete : false
  end
end

task :silly do
  puts "\nACME Auto Parts & Plumbing Corporation, Inc.\n".blue
  mark_line
  require 'pry'
  binding.pry
end
