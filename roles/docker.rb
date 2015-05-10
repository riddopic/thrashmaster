# encoding: UTF-8

name        'docker'
description 'Docker role'

override_attributes

run_list %w[
  recipe[docker::default]
]
