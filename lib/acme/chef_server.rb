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

require 'erb'

module ACME
  module Extensions
    # Mixin for creating and querying Chef users or Organizations.
    #
    module ChefServer
      # Creates a user on the Chef server. The validation key for the
      # organization is returned to STDOUT when creating a user with this
      # method.
      #
      # @param [Hash] user
      #   The options to create the user with.
      #
      # @option user [String] :user_name
      #   The user name to create.
      #
      # @option user [String] :first_name
      #   The first name of the user.
      #
      # @option user [String] :last_name
      #   The last name of the user.
      #
      # @option user [String] :email
      #   The users email address.
      #
      # @option user [String] :password
      #   The password to set on the account.
      #
      # @return [Array]
      #   The validation key.
      #
      def user_create(user = {})
        cmd = ['chef-server-ctl', 'user-create'] << user.values
        container.exec(cmd.flatten)[0][0]
      end

      # Retrieve a list of users on the Chef server.
      #
      # @return [Array]
      #
      def user_list
        cmd = ['chef-server-ctl', 'user-list']
        container.exec(cmd).flatten[0].split
      end

      # Create an organization on the Chef server. The validation key for the
      # organization is returned to STDOUT when creating an organization with
      # this method.
      #
      # @param [Hash] org
      #   The options to create the org with.
      #
      # @option org [String] :name
      #   The organization name must begin with a lower-case letter or digit,
      #   may only contain lower-case letters, digits, hyphens, and
      #   underscores, and must be between 1 and 255 characters.
      #
      # @option org [String] :full_name
      #   The full organization name must begin with a non-white space
      #   character and must be between 1 and 1023 characters.
      #
      # @option org [String] :association
      #   Associate a user with an organization and add them to the admins
      #   and billing_admins security groups.
      #
      def org_create(org = {})
        cmd = ['chef-server-ctl', 'org-create'] << org.values.insert(2, '-a')
        container.exec(cmd.flatten)[0]
      end

      # List all of the organizations currently present on the Chef server.
      #
      # @return [Array]
      #
      def org_list
        cmd = ['chef-server-ctl', 'org-list']
        container.exec(cmd).flatten[0].split
      end

      def render_data_bag(name, client_key, validation_key)
        cwd      = File.expand_path(File.dirname(__FILE__))
        data_bag = File.join(BASEDIR, 'lib', 'templates', 'data_bag.json.erb')
        template = ERB.new(File.read(data_bag))
        result   = template.result(binding)
        dest     = File.join(BASEDIR, 'data_bag', 'chef_org', "#{name}.json")
        open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << result }
      end

      def render_knife
        cwd      = File.expand_path(File.dirname(__FILE__))
        data_bag = File.join(BASEDIR, 'lib', 'templates', 'knife.rb.erb')
        template = ERB.new(File.read(data_bag))
        result   = template.result(binding)
        dest     = File.join(BASEDIR, '.chef', 'knife.rb')
        open(dest, File::CREAT|File::TRUNC|File::RDWR, 0644) { |f| f << result }
      end
    end
  end
end
