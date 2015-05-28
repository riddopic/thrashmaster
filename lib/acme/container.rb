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
  class Container
    # @!attribute [w] :name
    #   Assign a unique name identifier for this container instance.
    #   @return [String] Container Identification.
    attr_writer :name
    # @!attribute [w] :fqdn
    #   Assign the fully qualified host name of the container instance.
    #   @return [String] Container hostname.
    attr_writer :fqdn
    # @!attribute [w] :image
    #   Assign a docker image of the container instance.
    #   @return [String]
    attr_writer :image
    # @!attribute [rw] :roles
    #   Access the Chef roles for this instance of container.
    #   @return [Array]
    attr_accessor :roles
    # @!attribute [rw] :env
    #   A list of environment variables in the form of VAR=value.
    #   @return [String]
    attr_accessor :env
    # @!attribute [rw] :port
    #   A map of exposed container ports and the host port they should map to.
    #   It should be specified in the form { <port>/<protocol>: [{ "HostPort":
    #   "<port>" }] } Take note that port is specified as a string and not an
    #   integer value.
    #   @return [Hash]
    attr_accessor :port
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
    # @!attribute [r] :platform
    #   Returns the platform for this instance of container.
    #   @return [String]
    attr_reader :platform
    # @!attribute [r] :platform_version
    #   Returns the platform version for this instance of container.
    #   @return [String]
    attr_reader :platform_version

    def initialize(name)
      @name = name
    end

    # Request a Container by ID or name.
    #
    # @return [Docker::Container]
    #
    def container
      @container ||= Docker::Container.get(@name)
    end

    # Create a container.
    #
    # @return [Docker::Container]
    #
    def create
      Docker::Container.create(
        'name'         => @name,
        'Hostname'     => @name,
        'Domainname'   => PublicSuffix.parse(@fqdn).domain,
        'Env'          => @env,
        'Image'        => @image,
        'Volumes'      => @volumes,
        'HostConfig'   => { 'Binds' => @binds },
        'ExposedPorts' => { 22 => {} }.merge(Hash.new @ports)
      )
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
      container.exec(cmd) { |stream, chunk| puts "#{fqdn.purple}: #{chunk}" }
    end

    # Execute a SSH daemon on the container.
    #
    # @return [Docker::Container]
    #
    def run_sshd
      cmd = case @platform
            when 'alpine'
              alpine
            when 'rhel', 'centos', 'fedora'
              rhel
            when 'debian', 'ubuntu'
              debian
            else
              raise "Unknown platform '#{platform}'"
            end
      cmd << '-o PasswordAuthentication=yes -o UsePrivilegeSeparation=no'
      cmd << '-o PidFile=/tmp/sshd.pid'
      cmd = ['sh', '-c', cmd.join(' ')]
      container.exec(cmd, detach: true)
      self
    end

    # Bootstraps the container with Chef.
    #
    # @return [String]
    #   The output (result) of the chef-client run.
    #
    def bootstrap
      unless @roles.nil? || @roles.empty? || @platform == 'alpine'
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
      unless @roles.nil? || @roles.empty? || @platform == 'alpine'
        cmd = ['chef-client']
        container.exec(cmd) { |stream, chunk| puts "#{fqdn.purple}: #{chunk}" }
      end
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
    def running?
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

    private #        P R O P R I E T À   P R I V A T A   Vietato L'accesso

    def alpine
      cmd  = ["apk add --update openssh sudo bash &&\n"]
      cmd << ["ssh-keygen -A &&\n"]
      cmd << ['/usr/sbin/sshd -D -o UseDNS=no']
    end

    def rhel
      cmd  = ["yum clean all &&\n"]
      cmd << ["yum -y install sudo openssh-server openssh-clients   &&\n"]
      cmd << ["ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' &&\n"]
      cmd << ["ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' &&\n"]
      cmd << ['/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no']
    end

    def debian
      cmd  = ["apt-get-min update &&\n"]
      cmd << ["apt-get-install-min sudo openssh-server curl lsb-release &&\n"]
      cmd << ['/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no']
    end

    def osver
      cmd = ['[ -f /usr/bin/osver ] && /usr/bin/osver || echo "unknown"']
      cmd = ['sh', '-c', cmd.join(' ')]
      @osver ||= container.exec(cmd).flatten[0].split
    end
  end
end
