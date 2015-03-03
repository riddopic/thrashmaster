# encoding: UTF-8

name        'chef_client'
description 'Chef Client role'
override_attributes chef_client: { init: 'none' }
run_list %w[
  recipe[chef-client::delete_validation]
  recipe[chef-client::cron]
]
