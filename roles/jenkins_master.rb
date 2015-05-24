# encoding: UTF-8

name        'jenkins_master'
description 'Sir. Master Jenkins and his Pipeline role.'

default_attributes(
  java: {
    install_flavor: 'oracle',
    jdk_version: 7,
    oracle: {
      accept_oracle_download_terms: true
    }
  },
  nginx: {
    socketproxy: {
      default_app: 'default',
      apps: {
        default: {
          prepend_slash: false,
          context_name: '',
          subdir: 'current',
          socket: {
            type: 'tcp',
            port:  8080
          }
        }
      }
    }
  },
  jenkins: {
    master: {
      version: '1.596-1.1'
    }
  }
)

run_list %w[
  role[base]
  role[chef_client]
  recipe[pipeline::master]
]
