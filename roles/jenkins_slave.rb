# encoding: UTF-8

name        'jenkins_slave'
description 'A Slave called Jenkins and his Pipeline'

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
  recipe[pipeline::slave]
]
