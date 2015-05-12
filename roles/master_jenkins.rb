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
  },
  jenkins: {
    master: {
      version: '1.596-1.1'
    }
  }
)

run_list %w[
  recipe[pipeline::master]
]
