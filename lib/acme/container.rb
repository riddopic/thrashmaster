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

require 'public_suffix'

module ACME
  # Container objects form the basis of the container class, also known as the
  # dockers. These dockers are created, started, run, bootstraped and Chefed to
  # create the ACME Jelly and Wax Co. & Construction Supply.
  #
  class Container
    include ACME

    # @!attribute [rw] :name
    #   Access a unique name identifier for this container instance.
    #   @return [String] Container Identification.
    attr_accessor :name
    # @!attribute [rw] :fqdn
    #   Access the fully qualified host name of the container instance.
    #   @return [String] Container hostname.
    attr_accessor :fqdn
    # @!attribute [rw] :image
    #   Access the docker image of the container instance.
    #   @return [String]
    attr_accessor :image
    # @!attribute [rw] :roles
    #   Access the Chef roles for this instance of container.
    #   @return [Array]
    attr_accessor :roles
    # @!attribute [rw] :env
    #   A list of environment variables in the form of VAR=value.
    #   @return [String]
    attr_accessor :env
    # @!attribute [rw] :ports
    #   A map of exposed container ports and the host port they should map to.
    #   It should be specified in the form { <port>/<protocol>: [{ "HostPort":
    #   "<port>" }] } Take note that port is specified as a string and not an
    #   integer value.
    #   @return [Hash]
    attr_accessor :ports
    # @!attribute [rw] :volumes
    #   An object mapping mountpoint paths (strings) inside the container to
    #   empty objects.
    #   @return [Hash]
    attr_accessor :volumes
    # @!attribute [rw] :binds
    #   A list of volume bindings for this container. Each volume binding is a
    #   string of the form container_path (to create a new volume for the
    #   container), host_path:container_path (to bind-mount a host path into
    #   the container), or host_path:container_path:ro (to make the bind-mount
    #   read-only inside the container).
    #   @return [Array]
    attr_accessor :binds
    # @!attribute [rw] :privileged
    #   Give extended privileges to this container.
    #   @return [undefined]
    attr_accessor :privileged

    # Constructor for new container instance.
    #
    # @param [String] name
    #
    # @return [ACME::Container]
    #
    def initialize(name)
      @name = name
    end

    # Request a Container by ID or name.
    #
    # @return [Docker::Container]
    #
    def container
      @container ||= Docker::Container.get(@name)
    rescue Docker::Error::NotFoundError
      @container = nil
    end

    # Returns a hash of exposed ports for the container.
    #
    # @return [Hash]
    #
    def exposed_ports
      { 22 => {} }.merge(Hash.new @ports)
    end

    # Returns a hash of the host_config setting for the container.
    #
    # @return [Hash]
    #
    def host_config
      { 'Binds' => @binds, 'Privileged' => @privileged }
    end

    # Retrieve the domainname for the container.
    #
    # @return [String]
    #
    def domain
      @domain ||= PublicSuffix.parse(@fqdn).domain
    end

    # Evaluates the environment.
    #
    # @return [String]
    #
    def env # TODO: Cleanup...
      Proxy.running? ? [@env, Proxy.env, Proxy.no_proxy] : @env
      # return unless @env.blank? || @env.nil?
      # if @env.respond_to?(:each)
      #   @env.map { |e| e.respond_to?(:call) ? e.call : e }.join(' ')
      # elsif @env.respond_to?(:call)
      #   @env.call
      # end
    end

    # Create a container.
    #
    # @return [Docker::Container]
    #
    def create
      Docker::Container.create(
        'name'         => @name,
        'Hostname'     => @name,
        'Domainname'   => domain,
        'Env'          => env.join("\n"),
        'Image'        => @image,
        'Volumes'      => @volumes,
        'ExposedPorts' => exposed_ports,
        'HostConfig'   => host_config)
      self
    end

    # Starts the container.
    #
    # @return [Docker::Container]
    #
    def start
      container.start
      self
    end

    # Execute the command on the container.
    #
    # @params [Array, String] cmd
    #   The command to run specified as a string or an array of strings.
    #
    # @return [Docker::Container]
    #
    def exec(cmd)
      container.exec(cmd) { |_, chunk| puts "#{fqdn.purple}: #{chunk}" }
    end

    # Execute a SSH daemon on the container.
    #
    # @return [Docker::Container]
    #
    def run
      cmd  = platform_opts
      cmd << '-o PasswordAuthentication=yes'
      cmd << '-o UsePrivilegeSeparation=no'
      cmd << '-o PidFile=/tmp/sshd.pid'
      cmd = ['sh', '-c', cmd.join(' ')]
      container.exec(cmd, detach: true)
      self
    end

    # Helper to get platform specific options.
    #
    # @return [Array]
    #
    def platform_opts
      case platform
      when 'alpine'
        alpine
      when 'rhel', 'centos', 'fedora'
        rhel
      when 'debian', 'ubuntu'
        debian
      else
        raise "Unknown platform '#{platform}'"
      end
    end

    # Bootstraps the container with Chef.
    #
    # @return [String]
    #   The output (result) of the chef-client run.
    #
    def bootstrap
      unless @roles.nil? || @roles.empty? || platform == 'alpine'
        if platform =~ /(debian|ubuntu)/
          container.exec(['sh', '-c', 'apt-get-min update']) do |_, chunk|
            puts "#{fqdn.purple}: #{chunk}"
          end
        end
        system "knife bootstrap #{@fqdn} -x kitchen -N #{@name} " \
               "-r '#{@roles.join(', ')}' --sudo"
      end
      self
    end

    # Execute a chef-client process on the container.
    #
    # @return [String]
    #   The output (result) of the chef-client run.
    #
    def chef_client
      return if @roles.nil? || @roles.empty? || platform == 'alpine'
      cmd = ['chef-client']
      container.exec(cmd) { |_, chunk| puts "#{fqdn.purple}: #{chunk}" }
    end

    # Stop the container, will raise a `Docker::Error::NotFoundError` if the
    # container is not running.
    #
    # @raise [Docker::Error::NotFoundError]
    #
    # @return [Docker::Container]
    #
    def stop
      container.stop
      self
    end

    # Kill the container, will raise a `Docker::Error::NotFoundError` if the
    # container is not running.
    #
    # @raise [Docker::Error::NotFoundError]
    #
    # @return [Docker::Container]
    #
    def kill
      container.kill(signal: 'SIGHUP')
      sleep 0.5
      self
    end

    # Delete the container, will raise a `Docker::Error::NotFoundError` if the
    # container is not found in a stopped state.
    #
    # @raise [Docker::Error::NotFoundError]
    #
    # @return [Docker::Container]
    #
    def delete
      container.delete(force: true)
      @container = nil
    end

    # Boolean, true when the container has been created.
    #
    # @return [Boolean]
    #
    def created?
      running = Docker::Container.all(all: true)
      running.map { |r| r.info['Names'].include?("/#{@name}") }.any?
    end

    # Boolean, true when the container is running.
    #
    # @return [Boolean]
    #
    def started?
      status['Running']
    end

    # Returns the IP of the container.
    #
    # @return [String]
    #
    def ip
      container.json['NetworkSettings']['IPAddress']
    end

    # Display system-wide information about the container.
    #
    # @return [Hash]
    #
    def info
      container.info
    end

    # Display system information about the container.
    #
    # @return [Hash]
    #
    def config
      info['Config']
    end

    # Returns the containers current state.
    #
    # @example
    #   => {
    #             "Dead" => false,
    #            "Error" => "",
    #         "ExitCode" => 0,
    #       "FinishedAt" => "0001-01-01T00:00:00Z",
    #        "OOMKilled" => false,
    #           "Paused" => false,
    #              "Pid" => 0,
    #       "Restarting" => false,
    #          "Running" => false,
    #        "StartedAt" => "0001-01-01T00:00:00Z"
    #   }
    #
    # @return [Hash]
    #
    def status
      container.json['State']
    end

    # Return the platform of the container.
    #
    # @return [String]
    #
    def platform
      osver[0]
    end

    # Return the platform verion of the container.
    #
    # @return [String]
    #
    def platform_version
      osver[1]
    end

    private

    def alpine
      ['apk add --update openssh sudo bash', 'ssh-keygen -A'
      ].each { |cmd| container.exec(['sh', '-c', cmd], detach: true) }
      ['/usr/sbin/sshd -D -o UseDNS=no']
    end

    def rhel
      ['yum clean all',
       'yum -y install sudo openssh-server openssh-clients',
       'ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""',
       'ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ""'
      ].each { |cmd| container.exec(['sh', '-c', cmd], detach: true) }
      ['/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no']
    end

    def debian
      ['apt-get-min update',
       'apt-get-install-min sudo openssh-server curl lsb-release'
      ].each { |cmd| container.exec(['sh', '-c', cmd], detach: true) }
      ['/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no']
    end

    def osver
      cmd = ['[ -f /usr/bin/osver ] && /usr/bin/osver || echo "unknown"']
      cmd = ['sh', '-c', cmd.join(' ')]
      @osver ||= container.exec(cmd).flatten[0].split
    end
  end
end
