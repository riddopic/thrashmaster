# encoding: UTF-8

name        'users'
description 'Server hardening role'

default_attributes
override_attributes

run_list %w[
  recipe[users::sysadmins]
  recipe[thrashmaster::users]
]
