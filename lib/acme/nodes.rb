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
  container 'consul' do
    fqdn    'consul.acme.dev'
    image   'acme/consul'
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
    env     [->{ "JOIN_IP=#{join_ip}" }]
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
