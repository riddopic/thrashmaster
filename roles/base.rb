# encoding: UTF-8

name        'base'
description 'Base role applied to all nodes'

override_attributes(
  authorization: {
    sudo: {
      passwordless:      true,
      include_sudoers_d: true
    }
  }
)

run_list %w[
  recipe[ntp]
  recipe[sudo]
]
