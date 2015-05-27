# encoding: UTF-8

name        'hardening'
description 'Server hardening role'

default_attributes(
  authorization: {
    sudo: {
      groups: ['admin', 'wheel', 'sysadmin'],
      passwordless:      true,
      include_sudoers_d: true,
      sudoers_defaults:  ['!requiretty,!lecture,tty_tickets,!fqdn']
    }
  }
)

run_list %w[
  recipe[ntp::default]
  recipe[users::sysadmins]
  recipe[os-hardening::limits]
  recipe[os-hardening::login_defs]
  recipe[os-hardening::minimize_access]
  recipe[os-hardening::packages]
  recipe[os-hardening::pam]
  recipe[os-hardening::profile]
  recipe[os-hardening::securetty]
  recipe[os-hardening::suid_sgid]
  recipe[ssh-hardening::default]
  recipe[sudo::default]
]
