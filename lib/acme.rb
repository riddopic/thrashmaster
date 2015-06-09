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
require 'hoodie'
require 'net/ssh'

require_relative 'acme/utils'
require_relative 'acme/proxy'
require_relative 'acme/container_dsl'
require_relative 'acme/chef_server'
require_relative 'acme/container'
require_relative 'acme/prerequisites'
require_relative 'acme/rakelib'

# ACME Home Appliance & Sushi and Pet Supply, Inc.
#
# A Wholly-Owned Subsidiary of ACME Bail Bonds & Investment Corporation.
#
# Quality is our #1 dream!
#
module ACME
  # Construct Docker API connection using the environment variables from the
  # invoking shell.
  #
  Docker.url = ENV['DOCKER_HOST']
  Docker.options = {
    client_cert: File.join(ENV['DOCKER_CERT_PATH'], 'cert.pem'),
    client_key:  File.join(ENV['DOCKER_CERT_PATH'], 'key.pem'),
    ssl_ca_file: File.join(ENV['DOCKER_CERT_PATH'], 'ca.pem'),
    scheme: 'https'
  }

  @containers ||= []

  class << self
    attr_accessor :containers
  end

  def ret_ok
    'OK'.green
  end

  def ret_warn
    'Warning'.yellow
  end

  def ret_fail
    'Failed'.red
  end

  # Register a new container, note that we do not check for duplicates.
  #
  # @param [String] name
  #   The name of the container to register.
  #
  # @param [ACME::Container] container
  #   The container object.
  #
  def self.register(name, container)
    @containers << container
    instance_variable_set("@#{name}", container)
    self.class.send(:attr_accessor, name)
  end

  # Deregister a container.
  #
  # @param [String] name
  #   The name of the container to deregister.
  #
  def self.deregister(name)
    @containers.delete(name)
  end

  # Create a new container using the DSL.
  #
  # @param [String] name
  #   The name of the container to create.
  #
  # @param [Proc] block
  #   A block containing options for the container.
  #
  def self.container(name, &block)
    container     = Container.new(name)
    container_dsl = ContainerDSL.new(container)
    container_dsl.instance_eval(&block)
    register name, container
    container
  end

  # Creates a proc to be evaluated when called with `#.call'.
  #
  # @param [Proc] block
  #   The block to lazy evaluate.
  #
  # @return [LazyEvaluator]
  #
  def lazy(&block)
    ACME::LazyEvaluator.new(&block)
  end

  class LazyEvaluator < Proc; end

  # Hook called when an object is extended with ACME.
  #
  # @param [Object] object
  #
  # @return [undefined]
  #
  def self.extended(object)
    super
    object.instance_eval do
      extend ACME::Utils
      extend ACME::Rakelib
    end
  end
  private_class_method :extended
end
