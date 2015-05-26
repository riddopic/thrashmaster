# encoding: UTF-8

name        'base'
description 'Base role applied to all nodes'

default_attributes(
  tz: 'UTC',
  'auto-patch' => {
    monthly: 'fourth wednesday',
    prep: {
      disable: false,
      hour: 7,
      monthly: 'fourth wednesday'
    }
  }
)

run_list %w[
  recipe[baseos::default]
  role[chef_client]
  role[auto_patch]
  recipe[garcon::civilize]
  recipe[ntp::default]
  recipe[sudo::default]
  recipe[timezone-ii::default]
  recipe[users::sysadmins]
]
