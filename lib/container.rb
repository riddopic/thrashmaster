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

require 'docker'

class Container

  def initialize(name, image, env = nil)
    @name  = name
    @image = image
    @env   = env || [->{}]
    @fqdn  = name + '.' + DOMAINNAME
  end

  def container
    @container ||= Docker::Container.get(@name)
  end

  def create
    Docker::Container.create(
      'name'         => @name,
      'Hostname'     => @name,
      'Domainname'   => DOMAINNAME,
      'Env'          => @env[0].call,
      'Image'        => @image,
      'ExposedPorts' => { '22/tcp' => {} })
    self
  end

  def exist?
    all.map { |r| r.info['Names'].include?("/#{@name}") }.any?
  end

  def start
    container.start
    self
  end

  def exec(cmd)
    container.exec(cmd, tty: true)
    self
  end

  def stop
    container.stop
    self
  end

  def kill
    container.kill(signal: 'SIGHUP')
    self
  end

  def delete
    container.delete(force: true)
    self
  end
  alias_method :del, :delete
  alias_method :rm,  :delete

  def ip
    container.json['NetworkSettings']['IPAddress']
  end

  def info
    container.info
  end

  def state
    container.json['State']
  end
end
