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
DOTCHEF = File.join(BASEDIR, '.chef')
require_relative 'lib/acme'
extend ACME

# ------------------------------------------------------------------------------
def chef_server
  'chef.acme.dev'
end

def user
  { name:       'jenkins',
    first_name: 'George',
    last_name:  'Jenkins',
    email:      'george.jenkins@acme.com',
    password:   'beep-beep' }
end

def org
  { name:       'acme',
    long_name:  'ACME Auto Parts & Plumbing Co.',
    association: user[:name] }
end

def git
  { url:     'https://github.com/riddopic/thrashmaster.git',
    branch:  '*/master',
    polling: '* * * * *' }
end

VALIDATION  = File.join(DOTCHEF, "#{org[:name]}-validator.pem")
CLIENT_PEM  = File.join(DOTCHEF, "#{org[:name]}-#{user[:name]}.pem")
KNIFE_FILE  = File.join(DOTCHEF, 'knife.rb')
CERTS_DIR   = File.join(DOTCHEF, 'trusted_certs')
ORG_DATABAG = File.join(BASEDIR, 'data_bag', 'chef_org', "#{org[:name]}.json")
# ------------------------------------------------------------------------------

if ENV['USER'] == 'root'
  raise 'Running as root is unsupported, please use a non-root user account.'
  exit(1)
end

module ACME
  container 'squid' do
    image       'riddopic/squid'
    privileged   true
    networkmode :host
  end

  container 'router' do
    image       'riddopic/router'
    privileged   true
    networkmode :host
  end

  container 'consul' do
    fqdn    'consul.acme.dev'
    image   'riddopic/consul'
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  # container   'dockerui' do
  #   fqdn      'dockerui.acme.dev'
  #   image     'riddopic/dockerui'
  #   privileged true
  #   ports    ['80/tcp']
  #   volumes  ['/var/run/docker.sock' => {}]
  #   binds    ['/var/run/docker.sock:/var/run/docker.sock']
  # end

  # container  'seagull' do
  #   fqdn     'seagull.acme.dev'
  #   image    'riddopic/seagull'
  #   volumes ['/var/run/docker.sock' => {}]
  #   binds   ['/var/run/docker.sock:/var/run/docker.sock']
  # end

  container  'kibana' do
    fqdn     'kibana.acme.dev'
    image    'riddopic/kibana'
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container  'logstash' do
    fqdn     'logstash.acme.dev'
    image    'riddopic/ubuntu-14.04'
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container  'elasticsearch' do
    fqdn     'elasticsearch.acme.dev'
    image    'riddopic/ubuntu-14.04'
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container  'chef' do
    fqdn     'chef.acme.dev'
    image    'riddopic/chef-server'
    env     [
      "PUBLIC_URL=https://#{chef_server}",
      "OC_ID_ADMINISTRATORS=#{user[:name]}"
            ]
    roles   ['role[base]', 'role[chef_client]', 'role[hardening]']
  end

  container  'jenkins' do
    fqdn     'jenkins.acme.dev'
    image    'riddopic/centos-6'
    roles   ['role[base]', 'role[chef_client]', 'role[jenkins_master]']
  end

  container   'slave' do
    fqdn      'slave.acme.dev'
    image     'riddopic/docker'
    privileged true
    roles    ['role[base]', 'role[chef_client]', 'role[jenkins_slave]']
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
  puts "\nStarting Pipeline Stack".magenta
  mark_line

  startup_core
  docker_kernel
  startup_elkstack
  startup_chefstack
  timer(amount) # TODO: this could have brains.
  chef_bootstrap(user, org, git, chef_server)

  [ACME.jenkins, ACME.slave].each do |c|
    2.times { mark_line }
    system "figlet -f ogre #{c.name}"
    c.bootstrap
  end

  2.times do
    [ACME.jenkins, ACME.slave].each do |c|
      2.times { mark_line }
      system "figlet -f ogre #{c.name}"
      c.chef_client
    end
  end

  double_mark_line
  system 'knife status'
  2.times { mark_line }
end

desc 'Do the Chef'
task :chef do
  ACME.containers.each do |c|
    next if c.platform == 'alpine'
    next if c.name == 'squid' || c.name == 'router' || c.platform == 'alpine'

    2.times { mark_line }
    system "figlet -f ogre #{c.name}"
    c.chef_client
  end
end

desc 'Restart the  pipeline stack'
task :restart => [:stop, :start]

desc 'Stop and cleanup pipeline stack'
task :stop do
  ACME.containers.each do |c|
    next if c.name == 'squid' || c.name == 'router'
    printf "%-70s %-s\n",
      "Stoping and cleaning up container #{c.fqdn}:",
      "[#{ret_ok}]"
    begin
      if c.created?
        c.started? ? c.stop.delete : c.delete
      end
    rescue Docker::Error::ServerError
    end
  end
  [VALIDATION, CLIENT_PEM, KNIFE_FILE, CERTS_DIR, ORG_DATABAG].each do |file|
    FileUtils.rm_rf file if File.exist? file
  end
end

task :debug do
  puts "\nACME Auto Parts & Plumbing Corporation, Inc.\n".blue
  mark_line
  require 'pry'
  binding.pry
end
