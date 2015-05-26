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
require 'hoodie'
require 'net/ssh'
require_relative 'lib/machine'
require_relative 'lib/transition_table'
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

# *************************** Container definitions ****************************
#
containers  = []
base_role   = ['role[base]', 'role[chef_client]']

containers << @consul ||= Container.new(
  'consul',
  'riddopic/consul'
)

containers << @seagull ||= Container.new(
  'seagull',
  'riddopic/seagull',
  env:     [->{ "JOIN_IP=#{join_ip}" }],
  volumes: { '/var/run/docker.sock' => {} },
  binds:   [ '/var/run/docker.sock:/var/run/docker.sock' ]
)

containers << @kibana ||= Container.new(
  'kibana',
  'riddopic/kibana',
  roles: base_role,
  env:   [->{ "JOIN_IP=#{join_ip}" }]
)

containers << @logstash ||= Container.new(
  'logstash',
  'riddopic/logstash',
  roles: base_role,
  env:   [->{ "JOIN_IP=#{join_ip}" }]
)

containers << @elasticsearch ||= Container.new(
  'elasticsearch',
  'riddopic/elasticsearch',
  roles: base_role,
  env:   [->{ "JOIN_IP=#{join_ip}" }]
)

containers << @chef_server ||= Container.new(
  'chef',
  'riddopic/chef-server',
  roles: base_role,
  env:   [->{ "JOIN_IP=#{join_ip}" }]
)

containers << @jenkins_master ||= Container.new(
  'jenkins',
  'riddopic/centos-6',
  roles: [base_role, 'role[jenkins_master]'],
  env:   [->{ "JOIN_IP=#{join_ip}" }]
)

containers << @jenkins_slave ||= Container.new(
  'slave',
  'riddopic/docker',
  roles: [base_role, 'role[jenkins_slave]'],
  env:   [->{ "JOIN_IP=#{join_ip}" }]
)

#
# ******************************************************************************

def chef_user_exists?(user)
  command = ['bash', '-c', 'chef-server-ctl user-list']
  users = Docker::Container.get('chef').exec(command, tty: true)[0][0]
  users.gsub(/\s+/, ' ').strip.include?(user)
end

def create_chef_user(user, fullname, email, password, org)
  if chef_user_exists?(user)
    puts "The user #{user} already exists on the Chef server, not recreating."
  end
  cmd = %w[chef-server-ctl user-create] << user << fullname << email << password
  pemfile = File.join('.chef', "#{org}-#{user}.pem")
  command = ['bash', '-c', cmd.join(' ')]
  key = Docker::Container.get('chef').exec(command)[0][0].gsub(/\r\n?/, "\n")
  open(pemfile, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << key }
  @client_key = key
end

def chef_org_exists?(org)
  command = ['bash', '-c', 'chef-server-ctl org-list']
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
  command = ['bash', '-c', cmd.join(' ')]
  key = Docker::Container.get('chef').exec(command)[0][0].gsub(/\r\n?/, "\n")
  open(pemfile, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << key }
  @validation_key = key
end

def render_data_bag(org)
  cwd      = File.expand_path(File.dirname(__FILE__))
  data_bag = File.join(cwd, '.templates', 'data_bag.json.erb')
  template = ERB.new(File.read(data_bag))
  result   = template.result(binding)
  dest     = File.join(cwd, 'data_bag', 'chef_org', "#{org}.json")
  open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << result }
end

def render_knife
  cwd      = File.expand_path(File.dirname(__FILE__))
  data_bag = File.join(cwd, '.templates', 'knife.rb.erb')
  template = ERB.new(File.read(data_bag))
  result   = template.result(binding)
  dest     = File.join(cwd, '.chef', 'knife.rb')
  open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << result }
end

def docker_kernel
  puts "\nSetting Docker host SHMMAX and SHMALL kernel paramaters:"
  host = `docker-machine ip`.strip
  keys = [File.join(ENV['DOCKER_CERT_PATH'], 'id_rsa')]
  ['sudo sysctl -w kernel.shmmax=17179869184',
   'sudo sysctl -w kernel.shmall=4194304'
  ].each do |cmd|
    resp =  Net::SSH.start(host, 'docker', keys: keys) { |ssh| ssh.exec!(cmd) }
    printf "%1s %22s %-12s\n",  '', "[#{resp.strip.yellow}]", ''
  end
  puts
end

desc 'Start a full pipeline stack'
task :start do
  amount = exists?('chef') ? 3 : 160
  puts "\nStarting Pipeline Stack".yellow
  docker_kernel

  containers.each do |container|
    unless exists?(container.name)
      container.do(:create).do(:start).do(:run_sshd)

      printf "%-60s %10s\n",
             "Starting container #{container.hostname.red}:",
             "[#{container.ip.yellow}]"
      # Give the Consul node time to get an IP.
      sleep 2 if container.name == 'consul'
    end
  end

  puts "\nWaiting for Chef server to auto configure:".red
  sleep amount

  create_chef_user 'jenkins', 'Dr. J', 'jenkins@acme.dev', 'password', 'acme'
  create_chef_org  'acme', 'ACME Auto Parts & Plumbing Co.', 'jenkins'
  render_data_bag  'acme'
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

  containers.each do |container|
    container.do(:bootstrap)
    printf "%-60s %10s\n",
           "\nBootstraping container #{container.hostname.red}:", ''
  end
end
