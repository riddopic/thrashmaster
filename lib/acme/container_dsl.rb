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
  class ContainerDSL

    def join_ip
      @ip ||= Docker::Container.get('consul').
              json['NetworkSettings']['IPAddress']
    rescue Docker::Error::NotFoundError
      nil
    end

    def initialize(container)
      @container = container
    end

    def fqdn(fqdn)
      @container.fqdn = fqdn
    end

    def image(image)
      @container.image = image
    end

    def roles(roles)
      @container.roles ||= roles
    end

    def env(env)
      env = env.map { |e| e.respond_to?(:call) ? e.call : e }.join(' ')
      @container.env ||= env
    end

    def ports(ports)
      @container.ports ||= ports.join(' ')
    end

    def volumes(volumes)
      @container.volumes ||= volumes.join(' ')
    end

    def binds(binds)
      @container.binds ||= binds
    end
  end

  @registry ||= []

  def self.registry
    @registry
  end

  def self.register(container)
    @registry << container
  end

  def self.deregister(container)
    @registry.delete(container)
  end

  def self.container(name, &block)
    # Create a new Container object instance for our new container.
    container = Container.new(name)
    # Create a new instance of our Container DSL and pass it our newly
    # instantiated container.
    container_dsl = ContainerDSL.new(container)
    # Eval the container block within the ContainerDSL instance.
    container_dsl.instance_eval(&block)
    # Add the container to the registry.
    register(container)
    # Return the finished container
    container
  end
end
