# encoding: UTF-8

name        'hardening'
description 'Server hardening role'

default_attributes

run_list %w[
  recipe[baseos::default]
  recipe[ntp::default]
  recipe[os-hardening::limits]
  recipe[os-hardening::login_defs]
  recipe[os-hardening::minimize_access]
  recipe[os-hardening::packages]
  recipe[os-hardening::pam]
  recipe[os-hardening::profile]
  recipe[os-hardening::securetty]
  recipe[os-hardening::suid_sgid]
  recipe[ssh-hardening::default]
]
