# encoding: UTF-8

name        'chef_client'
description 'Chef Client role'

override_attributes(
  chef_client: {
    init:        'none',
    splay:        300,
    logrotate: {
      rotate:     6,
      frequency: 'weekly'
    },
    cron: {
      log_file:   '/var/log/chef/client.log',
      minute:     0,
      hour:      '0,4,8,12,16,20',
      weekday:   '*',
      append_log: true
    }
  }
)

run_list %w[
  recipe[chef_handler::default]
  recipe[cron::default]
  recipe[chef-client::delete_validation]
  recipe[chef-client::cron]
]
