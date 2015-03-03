# encoding: UTF-8

name        'production'
description 'Production Environment.'

cookbook_versions(
  'apt'             => '= 2.6.1',
  'build-essential' => '= 2.1.3',
  'chef-dk'         => '= 3.0.0',
  'chef-zero'       => '= 2.0.1',
  'chef_handler'    => '= 1.1.6',
  'cron'            => '= 1.6.1',
  'dmg'             => '= 2.2.2',
  'docker'          => '= 0.34.2',
  'emacs'           => '= 0.9.2',
  'git'             => '= 4.1.0',
  'java'            => '= 1.31.0',
  'jenkins'         => '= 2.2.2',
  'logrotate'       => '= 1.8.0',
  'resolver'        => '= 1.2.0',
  'runit'           => '= 1.5.16',
  'sudo'            => '= 2.7.1',
  'users'           => '= 1.7.0',
  'windows'         => '= 1.36.6',
  'yum'             => '= 3.5.3',
  'chef-client'     => '= 4.2.4',
  'os-hardening'    => '= 1.2.0',
  'pipeline'        => '= 0.2.0',
  'ssh-hardening'   => '= 1.0.3'
)
