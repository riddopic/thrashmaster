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

  attr_reader :name

  attr_reader :roles

  attr_reader :fqdn

  attr_reader :hostname

  attr_reader :platform

  attr_reader :platform_version

  def initialize(name, image, roles: [], env: [->{}], ports: {}, volumes: {}, binds: [])
    @name    = name
    @image   = image
    @roles   = roles
    @env     = env
    @ports   = ports
    @volumes = volumes
    @binds   = binds
    @fqdn    = name + '.' + DOMAINNAME
  end

  def container
    @container ||= Docker::Container.get(@name)
  end

  def create
    Docker::Container.create(
      'name'         => @name,
      'Hostname'     => @name,
      'Domainname'   => DOMAINNAME,
      'Env'          => @env.map { |e| e.respond_to?(:call) ? e.call : e },
      'Image'        => @image,
      'Volumes'      => @volumes,
      'HostConfig'   => { 'Binds' => @binds },
      'ExposedPorts' => { 22 => {} }.merge(Hash.new @ports)
    )
    self
  end

  def hostname
    "#{config['Hostname']}.#{config['Domainname']}"
  end

  def running?
    state['Running']
  end

  def start
    container.start unless running?
    self
  end

  def stop
    container.stop if running?
    self
  end

  def exec(cmd)
    container.exec(cmd, tty: true)
    self
  end

  def kill
    container.kill(signal: 'SIGHUP') if running?
    sleep 0.5
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

  def config
    container.info['Config']
  end

  def info
    container.info
  end

  # Returns the containers current state.
  #
  # @return [Hash]
  #
  def state
    container.json['State']
  end

  # Bootstraps the Chef Client onto the container.
  #
  def bootstrap
    system "knife bootstrap #{@fqdn} -x kitchen -N #{@name} " \
           "-r '#{@roles.join(', ')}' --sudo" unless platform == 'alpine'
    self
  end

  def run_sshd
    cmd = []
    case platform
    when 'alpine'
      cmd << "apk add --update openssh sudo bash &&\n"
      cmd << "ssh-keygen -A &&\n"
      cmd << '/usr/sbin/sshd -D -o UseDNS=no'
    when 'rhel', 'centos', 'fedora'
      cmd << "yum clean all &&\n"
      cmd << "yum -y install sudo openssh-server openssh-clients   &&\n"
      cmd << "ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' &&\n"
      cmd << "ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' &&\n"
      cmd << '/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no'
    when 'debian', 'ubuntu'
      cmd << "apt-get-min update &&\n"
      cmd << "apt-get-install-min sudo openssh-server curl lsb-release &&\n"
      cmd << '/usr/sbin/sshd -D -o UseDNS=no -o UsePAM=no'
    else
      raise "Unknown platform '#{platform}'"
    end
    cmd << '-o PasswordAuthentication=yes -o UsePrivilegeSeparation=no'
    cmd << '-o PidFile=/tmp/sshd.pid'
    run = ['sh', '-c', cmd.join(' ')]
    container.exec(run, detach: true)
    self
  end

  def platform;         osver[0]; end
  def platform_version; osver[1]; end

  def osver
    cmd = %w[[ -f /usr/bin/osver ] && /usr/bin/osver || echo 'unknown']
    run = ['sh', '-c', cmd.join(' ')]
    @osver ||= container.exec(run).flatten[0].split
  end

  private #        P R O P R I E T À   P R I V A T A   Vietato L'accesso

  def osver
    cmd = %w[[ -f /usr/bin/osver ] && /usr/bin/osver || echo 'unknown']
    run = ['sh', '-c', cmd.join(' ')]
    @osver ||= container.exec(run).flatten[0].split
  end
end
