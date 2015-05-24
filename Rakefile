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

$: << File.dirname(__FILE__) + './lib'

require 'erb'
require 'rake'
require 'docker'
require_relative 'lib/container'

Docker.url = ENV['DOCKER_HOST']
Docker.options = {
  client_cert: File.join(ENV['DOCKER_CERT_PATH'], 'cert.pem'),
  client_key:  File.join(ENV['DOCKER_CERT_PATH'], 'key.pem'),
  ssl_ca_file: File.join(ENV['DOCKER_CERT_PATH'], 'ca.pem'),
  scheme: 'https'
}

DOMAINNAME = 'mudbox.dev'

def org_data
  {
    org:         'acme',
    long_name:   'ACME Auto Parts & Plumbing Co.',
    user:        'jenkins',
    fullname:    'Mr. Jenkins',
    email:       'jenkins@acme.dev',
    password:    'password',
    chef_server: 'https://chef.mudbox.dev/',
    git_url:     'https://github.com/riddopic/thrashmaster.git'
  }
end

def repo_data
  {
    name:    org_data[:org],
    url:     org_data[:git_url],
    branch:  '*/master',
    polling: '* * * * *'
  }
end

# Returns a list of all containers from the endpoint.
#
# @param [Boolean] all
#   When true will show all containers (started and stopped), when false only
#   running containers are listed.
#
# @return [Array]
#
def running(all = true)
  Docker::Container.all(all: true)
end

# Check to see if a given container exists, it is considered to exists if it has
# a state of restarting, running, paused, exited
#
def exists?(id)
  running.map { |r| r.info['Names'].include?("/#{id}") }.any?
end

def join_ip
  @ip ||= Docker::Container.get('consul').json['NetworkSettings']['IPAddress']
rescue Docker::Error::NotFoundError
  nil
end

def consul
  @consul ||= Container.new('consul', 'riddopic/consul')
end

def kibana
  @kibana ||= Container.new(
    'kibana', 'riddopic/kibana', [->{ "JOIN_IP=#{join_ip}" }])
end

def logstash
  @logstash ||= Container.new(
    'logstash', 'riddopic/logstash', [->{ "JOIN_IP=#{join_ip}" }])
end

def elasticsearch
  @elasticsearch ||= Container.new(
    'elasticsearch', 'riddopic/elasticsearch', [->{ "JOIN_IP=#{join_ip}" }])
end

def chef_server
  @chef_server ||= Container.new(
    'chef', 'riddopic/chef-server', [->{ "JOIN_IP=#{join_ip}" }])
end

def jenkins_master
  @jenkins_master ||= Container.new(
    'jenkins', 'riddopic/centos-6', [->{ "JOIN_IP=#{join_ip}" }])
end

def jenkins_slave
  @jenkins_slave ||= Container.new(
    'slave', 'riddopic/docker', [->{ "JOIN_IP=#{join_ip}" }])
end

def chef_user_exists?(user)
  command = ["bash", "-c", "chef-server-ctl user-list"]
  users = Docker::Container.get('chef').exec(command, tty: true)[0][0]
  users.gsub(/\s+/, ' ').strip.include?(user)
end

def create_chef_user(user, fullname, email, password, org)
  if chef_user_exists?(user)
    puts "The user #{user} already exists on the Chef server, not recreating."
  end
  cmd = %w[chef-server-ctl user-create] << user << fullname << email << password
  pemfile = File.join('.chef', "#{org}-#{user}.pem")
  command = ["bash", "-c", cmd.join(' ')]
  key = Docker::Container.get('chef').exec(command, tty: true)[0]
  open(pemfile, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f.puts key }
  @client_key = key[0].gsub /\r\n?/, "\n"
end

def chef_org_exists?(org)
  command = ["bash", "-c", "chef-server-ctl org-list"]
  users = Docker::Container.get('chef').exec(command, tty: true)[0][0]
  users.gsub(/\s+/, ' ').strip.include?(org)
end

def create_chef_org(org, long_name, user)
  if chef_org_exists?(org)
    puts "The org #{org} already exists on the Chef server, not recreating."
  end
  cmd  = %w[chef-server-ctl org-create] << org << "'#{long_name}'"
  cmd << '--association' << user
  pemfile = File.join('.chef', "#{org}-validator.pem")
  command = ["bash", "-c", cmd.join(' ')]
  key = Docker::Container.get('chef').exec(command, tty: true)[0]
  open(pemfile, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f.puts key }
  @validation_key = key[0].gsub /\r\n?/, "\n"
end

def render_data_bag(org)
  cwd      = File.expand_path(File.dirname(__FILE__))
  data_bag = File.join(cwd, '.templates', 'data_bag.json.erb')
  template = ERB.new(File.read(data_bag))
  result   = template.result(binding)
  dest     = File.join(cwd, 'data_bags', 'chef_org', "#{org}.json")

  open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f.puts result }
end

def render_knife
  cwd      = File.expand_path(File.dirname(__FILE__))
  data_bag = File.join(cwd, '.templates', 'knife.rb.erb')
  template = ERB.new(File.read(data_bag))
  result   = template.result(binding)
  dest     = File.join(cwd, '.chef', 'knife.rb')

  open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f.puts result }
end

def bootstrap(fqdn, roles)
  cmd  = %w[knife bootstrap] << fqdn << '--sudo -x kitchen -N' << fqdn
  cmd << "-r '#{roles.join(', ')}'"
  command = ["bash", "-c", cmd.join(' ')]
  Docker::Container.get(fqdn.split('.')[0]).exec(command) do |stream, chunk|
    puts chunk
  end
end

containers = [
  consul,
  kibana,
  logstash,
  elasticsearch,
  chef_server,
  jenkins_master,
  jenkins_slave
]

namespace :pipeline do
  desc 'Start a full pipeline stack'
  task :start do
    amount = exists?('chef') ? 3 : 160

    # TODO: assumes the docker-machine name dev...?
    puts "\nSetting Docker host SHMMAX and SHMALL kernel paramaters:"
    system "docker-machine ssh dev 'sudo sysctl -w kernel.shmmax=17179869184'"
    system "docker-machine ssh dev 'sudo sysctl -w kernel.shmmax=4194304'"

    puts "\nStarting Consul server:"
    consul.create.start
    sleep 2 # Give the Consul node time to get an IP.

    puts "\nStarting remaning containers:"

    [ kibana,
      logstash,
      elasticsearch,
      chef_server,
      jenkins_master,
      jenkins_slave
    ].each { |container| container.create.start }

    puts "\nWaiting for Chef server to auto configure:"
    sleep amount

    create_chef_user 'jenkins', 'Dr. J', 'jenkins@acme.dev', 'password', 'acme'
    create_chef_org 'acme', 'ACME Auto Parts & Plumbing Co.', 'jenkins'
    render_data_bag 'acme'
    render_knife

    system 'knife ssl fetch'
    system 'berks install -c .berkshelf/config.json'
    system 'berks upload  -c .berkshelf/config.json'
    system 'knife environment from file environments/*'
    system 'knife role        from file roles/*'
    system 'knife data bag create    chef_org'
    system 'knife data bag from file chef_org data_bags/chef_org/*'
    system 'knife cookbook upload pipeline --freeze --force'

    puts "\nBootstraping Kibana:"
    bootstrap 'jenkins', %w[role[base] role[chef_client]]

    puts "\nBootstraping Logstash:"
    bootstrap 'jenkins', %w[role[base] role[chef_client]]

    puts "\nBootstraping Elasticsearch:"
    bootstrap 'jenkins', %w[role[base] role[chef_client]]

    puts "\nBootstraping Chef Server:"
    bootstrap 'jenkins', %w[role[base] role[chef_client]]

    puts "\nBootstraping Jenkins master:"
    bootstrap 'jenkins', %w[role[base] role[chef_client] role[jenkins_master]]

    puts "\nBootstraping Jenkins slave:"
    bootstrap 'slave',   %w[role[base] role[chef_client] role[jenkins_slave]]
  end

  desc 'Stop the pipeline stack'
  task :stop do
    containers.map { |c| c.stop }
  end

  desc 'Kill the pipeline stack'
  task :kill do
    containers.map { |c| c.kill }
  end

  desc 'Delete the pipeline stack'
  task :del do
    containers.map { |c| c.kill.del }
  end
end

task :nuke do
  system "docker kill   $(docker ps -q)"
  system "docker rm  -f $(docker ps -a | grep Exited | awk '{print $1}')"
  system "docker rmi -f $(docker images -q --filter 'dangling=true')"
end
