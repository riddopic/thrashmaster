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
  # Assist in the DSL of Container class objects, makes it possible to
  # syntactically go where no artificial sweetner has gone before.
  #
  class ContainerDSL
    include ACME

    def initialize(container)
      @container = container
    end

    def fqdn(fqdn)
      @container.fqdn = fqdn
    end

    def image(image)
      @container.image = image
    end

    def privileged(privileged = false)
      @container.privileged ||= privileged
    end

    def roles(roles)
      @container.roles ||= roles
    end

    def env(env)
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
end
