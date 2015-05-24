# encoding: UTF-8

name        'auto_patch'
description 'Automatically patch nodes on a given time and day.'

default_attributes 'auto-patch' => { hour: 22 }

run_list %w[
  recipe[auto-patch::default]
]
