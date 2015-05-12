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

namespace :chef do
  namespace :server do
    desc 'Terminate a Chef Server'
    task :terminate do
      system 'kitchen destroy'
    end

    desc 'Launch a Chef Server'
    task :launch do
      system 'say -v Samantha Starting up a Chef server'
      system 'kitchen create'
      system 'say -v Samantha This will take a minute'
      sleep 40
      system 'say -v Samantha Almost ready'
      sleep 20

      system 'ssh root@chef.mudbox.dev chef-server-ctl status'
      system 'kitchen converge'
      system 'rm -rf .chef/trusted_certs'
      system 'scp root@chef.mudbox.dev:pipeline-jenkins.pem   ~/.chef'
      system 'scp root@chef.mudbox.dev:pipeline-validator.pem ~/.chef'
      system 'knife ssl fetch'
      system 'berks install -c .berkshelf/config.json'
      system 'berks upload  -c .berkshelf/config.json'
      system 'knife environment from file environments/*'
      system 'knife role        from file roles/*'
      system 'knife data bag create    chef_organizations'
      system 'knife data bag from file chef_organizations ' \
               'data_bags/chef_organizations/*'
      system 'knife cookbook upload pipeline --freeze --force'

      system 'say -v Samantha Your Thrash 12 simple local bootstrap Chef ' \
               'master immutable server is ready!'
    end
  end
end
