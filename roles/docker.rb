# encoding: UTF-8

name        'docker'
description 'Docker role'

default_attributes(
  docker: {
    package: {
      repo_url: 'https://get.docker.io/ubuntu'
    }
  }
)

run_list %w[
  recipe[docker::default]
]
