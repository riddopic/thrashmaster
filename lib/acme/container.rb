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
    # Container state machine transitions.
    #
    STATE_TRANSITIONS = TransitionTable.new(
      # State                Input           Next state            Output
      [:awaiting_create,    :create   ] => [:awaiting_start,     :do_create   ],
      [:awaiting_start,     :start    ] => [:awaiting_run_sshd,  :do_start    ],
      [:awaiting_run_sshd,  :run_sshd ] => [:awaiting_bootstrap, :do_run_sshd ],
      [:awaiting_bootstrap, :bootstrap] => [:awaiting_stop,      :do_bootstrap],
      [:awaiting_stop,      :stop     ] => [:awaiting_delete,    :do_stop     ],
      [:awaiting_delete,    :delete   ] => [:dead_and_gone,      :do_deleted  ]
    )

    attr_accessor :name
    attr_accessor :fqdn
    attr_accessor :image
    attr_accessor :roles
    attr_accessor :env
    attr_accessor :port
    attr_accessor :volumes
    attr_accessor :binds

    def initialize(name)
      @machine = Machine.new(STATE_TRANSITIONS, :awaiting_create)
      @name    = name
    end

    def do(event)
      action = @machine.send_input(event)
      send(action) unless action.nil?
      self
    end

    def container
      @container ||= Docker::Container.get(@name)
    end

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
    alias_method :do_create, :create

    def start
      container.start
      self
    end
    alias_method :do_start, :start

    def run_sshd
      cmd = case platform
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
    alias_method :do_run_sshd, :run_sshd

    def bootstrap
      unless @roles.nil? || @roles.empty?
        system "knife bootstrap #{@fqdn} -x kitchen -N #{@name} " \
               "-r '#{@roles.join(', ')}' --sudo"
        end
      self
    end
    alias_method :do_bootstrap, :bootstrap

    def chef_client
      unless @roles.nil? || @roles.empty?
        cmd = ['chef-client']
        container.exec(cmd) { |stream, chunk| puts "#{fqdn.purple}: #{chunk}" }
      end
    end
    alias_method :do_chef_client, :chef_client

    def stop
      container.stop
      self
    end
    alias_method :do_stop, :stop

    def kill
      container.kill(signal: 'SIGHUP')
      sleep 0.5
      self
    end
    alias_method :do_kill, :kill

    def delete
      container.delete(force: true)
      @container = nil
    end
    alias_method :do_delete, :delete

    def created?
      running = Docker::Container.all(all: true)
      running.map { |r| r.info['Names'].include?("/#{@name}") }.any?
    end
    alias_method :exist?, :created?

    def running?
      status['Running']
    end

    def ip
      container.json['NetworkSettings']['IPAddress']
    end

    def info
      container.info
    end

    def config
      info['Config']
    end

    # Returns the containers current state.
    #
    # @return [Hash]
    #
    def status
      container.json['State']
    end

    def platform
      osver[0]
    end

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
