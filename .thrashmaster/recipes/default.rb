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

include_recipe 'garcon::development'
include_recipe 'garcon::civilize'

execute 'create-admin-user' do
  command <<-EOF
  chef-server-ctl user-create jenkins Sir Jenkins jinx@hijinx.com password \
    --filename /root/pipeline-jenkins.pem
  EOF
  not_if 'chef-server-ctl user-list | grep jenkins'
end

execute 'create-organization' do
  command <<-EOF
  chef-server-ctl org-create pipeline 'PipeLine of America Corporation Inc.' \
    --association jenkins --filename /root/pipeline-validator.pem
  EOF
  not_if 'chef-server-ctl org-list | grep pipeline'
end
