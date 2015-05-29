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

if ENV["USER"] == "root"
  raise "Do not run this as root, do not run anything as root, forget the word"\
        "root! Bad, bad things could happen, then again, it could also work..."
  exit(1)
end

def o
  {
    org:         'acme',
    long_name:   'ACME Auto Parts & Plumbing Co.',
    user:        'jenkins',
    full_name:   'Mr. Jenkins',
    email:       'jenkins@acme.dev',
    passwd:      'password',
    chef_server: 'chef.acme.dev',
    git_url:     'https://github.com/riddopic/thrashmaster.git',
    branch:      '*/master',
    polling:     '* * * * *'
  }
end

module ACME
  container 'consul' do
    fqdn    'consul.acme.dev'
    image   'riddopic/consul'
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'seagull' do
    fqdn    'seagull.acme.dev'
    image   'riddopic/seagull'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    volumes ['/var/run/docker.sock' => {}]
    binds   ['/var/run/docker.sock:/var/run/docker.sock']
  end

  container 'kibana' do
    fqdn    'kibana.acme.dev'
    image   'riddopic/kibana'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'logstash' do
    fqdn    'logstash.acme.dev'
    image   'riddopic/logstash'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'elasticsearch' do
    fqdn    'elasticsearch.acme.dev'
    image   'riddopic/elasticsearch'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'chef' do
    fqdn    'chef.acme.dev'
    image   'riddopic/chef-server'
    env     [->{ "JOIN_IP=#{join_ip}" },
             "PUBLIC_URL=https://#{o[:chef_server]}",
             "OC_ID_ADMINISTRATORS=#{o[:jenkins]}"]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container 'jenkins' do
    fqdn    'jenkins.acme.dev'
    image   'riddopic/centos-6'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[jenkins_master]']
  end

  container 'slave' do
    fqdn    'slave.acme.dev'
    image   'riddopic/docker'
    env     [->{ "JOIN_IP=#{join_ip}" }]
    roles   ['role[base]', 'role[chef_client]', 'role[jenkins_slave]']
  end
end

desc 'Start a full pipeline stack'
task :start do
  amount = exists?('chef') ? 3 : 160

  puts "\nACME Auto Parts & Plumbing Corporation, Inc.\n".blue
  puts 'Welcome to ACME Auto Parts & Plumbing, a Wholly-Owned Subsidiary of'
  puts 'ACME Bait & Tackle Corporation where quality is our #1 dream! This is'
  puts 'the ACME operations repository of development cooking and pipe laying,'
  puts 'continuously for delivery, please enjoy the tour.'
  puts "\nStarting Pipeline Stack".yellow
  mark_line

  c = ACME.consul
  c.created? ? c.started? ? c.run : c.start.run : c.create.start.run
  printf "%-60s %-10s\n",
         "Starting container #{c.fqdn.orange}:", "[#{c.ip.yellow}]"

  ACME::Prerequisites.validate

  docker_kernel

  ACME.containers.each do |c|
    unless c.created?
      c.create.start.run

      printf "%-60s %-10s\n",
             "Starting container #{c.fqdn.orange}:", "[#{c.ip.yellow}]"
    end
  end

  puts "\nWaiting for Chef server to auto configure:\n".red
  progress_bar amount
  puts

  # run (method, discription, result)

  printf "%-60s %-10s\n",
         "Creating '#{o[:user].orange}' user on the Chef server:", "[#{ok}]"
  create_chef_user o[:user], o[:full_name], o[:email], o[:passwd], o[:org]

  printf "%-60s %-10s\n", "Creating #{o[:long_name].orange} org:", "[#{ok}]"
  create_chef_org o[:org], o[:long_name], o[:user]

  printf "%-60s %-10s\n",
         "Creating data bags for #{o[:org].orange} org:", "[#{ok}]"
  render_data_bag o[:org]
  render_knife

  printf "%-60s %-10s\n", "Fetching server SSL certificates:", "[#{warning}]"
  system 'knife ssl fetch'

  system 'berks install -c .berkshelf/config.json'
  system 'berks upload  -c .berkshelf/config.json'
  system 'knife environment from file environments/*'
  system 'knife role from file roles/*'
  system 'knife data bag create chef_org'
  system 'knife data bag create users'
  system 'knife data bag from file chef_org data_bag/chef_org/*'
  system 'knife data bag from file users data_bag/users/*'
  system 'knife cookbook upload pipeline --freeze --force'

  ACME.containers.each do |c|
    mark_line
    printf "%-60s %-10s\n", "\nBootstraping container #{c.fqdn.red}:", ''
    c.bootstrap
  end
end

desc 'Do the Chef'
task :chef do
  ACME.containers.each do |c|
    mark_line
    printf "%-60s %-10s\n",
           "\nExecuting chef-client on container #{c.fqdn.red}:", ''
    c.chef_client
  end
end

desc 'Stop and cleanup pipeline stack'
task :clean do
  ACME.containers.each do |c|
    mark_line
    printf "%-60s %-10s\n",
           "\nStoping and cleaning up container #{c.fqdn.red}:", ''
    c.created? ? c.started? ? c.stop.delete : c.delete : false
  end
end

task :debug do
  puts "\nACME Auto Parts & Plumbing Corporation, Inc.\n".blue
  mark_line
  require 'pry'
  binding.pry
end
