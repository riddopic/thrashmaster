# encoding: UTF-8

name        'production'
description 'Production Environment.'

cookbook_versions(
  'build-essential' => '= 2.1.3',
  'chef-client'     => '= 4.2.4',
  'chef-dk'         => '= 3.0.0',
  'chef_handler'    => '= 1.1.6',
  'cron'            => '= 1.6.1',
  'docker'          => '= 0.36.0',
  'git'             => '= 4.1.0',
  'java'            => '= 1.31.0',
  'jenkins'         => '= 2.2.2',
  'ntp'             => '= 1.7.0',
  'os-hardening'    => '= 1.2.0',
  'pipeline'        => '= 0.2.0',
  'ssh-hardening'   => '= 1.0.3',
  'sudo'            => '= 2.7.1',
  'yum'             => '= 3.5.3',
  'yum-epel'        => '= 0.6.0'
)
