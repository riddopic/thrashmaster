# encoding: UTF-8

name        'master_jenkins'
description 'Sir. Master Jenkins and his Pipeline role.'

default_attributes(
  java: {
    install_flavor: 'oracle',
    jdk_version: 7,
    oracle: {
      accept_oracle_download_terms: true
    }
  }
)

run_list %w[
  recipe[java]
  recipe[jenkins::master]
  recipe[git::default]
]
