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
  },
  authorization: {
    sudo: {
      groups:          ['admin', 'wheel', 'sysadmin'],
      passwordless:      true,
      include_sudoers_d: true,
      sudoers_defaults:  ['!requiretty,!lecture,tty_tickets,!fqdn']
    }
  }
)

run_list %w[
  recipe[baseos::default]
  recipe[garcon::civilize]
  recipe[ntp::default]
  recipe[sudo::default]
  recipe[timezone-ii::default]
  recipe[users::sysadmins]
]
