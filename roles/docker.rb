# encoding: UTF-8

name        'docker'
description 'Docker role'

override_attributes chef_client: { init: 'none' }

run_list %w[
  recipe[docker::default]
]
