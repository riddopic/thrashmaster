# encoding: UTF-8

name        'base'
description 'Base role applied to all nodes'

override_attributes(
  ntp: {
    servers: %w[
      0.centos.pool.ntp.org
      1.centos.pool.ntp.org
      2.centos.pool.ntp.org
      3.centos.pool.ntp.org
    ]
  },
  authorization: {
    sudo: {
      passwordless:      true,
      include_sudoers_d: true
    }
  }
)

run_list %w[
  recipe[ntp]
  recipe[os-hardening]
  recipe[ssh-hardening]
  recipe[sudo]
]
