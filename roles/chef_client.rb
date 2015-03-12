# encoding: UTF-8

name        'chef_client'
description 'Chef Client role'

override_attributes(
  chef_client: {
    init: 'none',
    cron: {
      log_file:   '/var/log/chef/client.log',
      append_log: true
    }
  }
)

run_list %w[
  recipe[cron::default]
  recipe[chef-client::delete_validation]
  recipe[chef-client::cron]
]
