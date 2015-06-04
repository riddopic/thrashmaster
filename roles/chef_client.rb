# encoding: UTF-8

name        'chef_client'
description 'Chef Client role'

default_attributes(
  omnibus_updater: {
    version: '12.3.0'
  },
  chef_client: {
    init:        'none',
    splay:        300,
    logrotate: {
      rotate:     6,
      frequency: 'weekly'
    },
    cron: {
      log_file:  '/var/log/chef/client.log',
      minute:     0,
      hour:      '0,4,8,12,16,20',
      weekday:   '*',
      append_log: true
    }
  }
)

run_list %w[
  recipe[baseos::default]
  recipe[chef_handler::default]
  recipe[omnibus_updater]
  recipe[cron::default]
  recipe[chef-client::delete_validation]
  recipe[chef-client::cron]
]
