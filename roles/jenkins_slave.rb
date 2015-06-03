# encoding: UTF-8

name        'jenkins_slave'
description 'A Slave called Jenkins and his Pipeline'

override_attributes jenkins: { proxy: { url: '10.0.0.6', port: 8123 } }

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
  recipe[sudo::default]
  recipe[baseos::default]
  recipe[build-essential]
  recipe[pipeline::slave]
]
