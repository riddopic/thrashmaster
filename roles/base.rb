# encoding: UTF-8

name        'base'
description 'Base role applied to all nodes'

override_attributes(
  authorization: {
    sudo: {
      passwordless:      true,
      include_sudoers_d: true,
      sudoers_defaults:  ['!requiretty,!lecture,tty_tickets,!fqdn']
    }
  }
)

run_list %w[
  recipe[ntp]
  recipe[sudo]
]
