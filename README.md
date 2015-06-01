
# ACME Auto Parts & Plumbing Corporation, Inc.

Welcome to ACME Auto Parts & Plumbing, a Wholly-Owned Subsidiary of ACME Bait & Tackle Corporation where quality is our #1 dream! This is the ACME operations repository of development cooking and pipe laying, continuously.

## Overview

This is a artistic rendering of a proof-of-concept Jenkins pipeline complete with a Chef Server, [ELKstack](elksack) ([Elasticsearch](elasticsearch), [Logstash](logstash), and [Kibana](kinana)), [Consul](consul) and [Seagull](seagull) running as Docker containers using Google Kubernetes.

The docker containers used for this pipeline are somewhat unorthodox by design, because docker is so light-weight it provides and excellent platform for running a large number of simultaneous machines. As such they do not follow the normal Docker practice of lightweight containers running a single process. Instead these are FatBoy™ containers complete with a process supervisor, SSH, [Consul](consul), cron, logrotation and NTP.

## Base images:

The containers are built from four different base images. Each image is
configured with [s6](s6) as the init process, and [Serf](serf) is used for node
discovery. The Yum and/or Apt repositories use a local mirror, additionally both
Ubuntu and CentOS images have the chef-stable repository installed (mirrored
locally). CentOS containers also have the EPEL repo installed.

 * Alpine Linux 3.1
 * CentOS 6.6
 * CentOS 7.1
 * Fedora 21
 * Ubuntu 12.04
 * Ubuntu 14.04

### Chef 12 Server

Based off the Ubuntu 'FatBoy' 14.04 image, this Chef server is not configured
with any redundancy nor is any of the data backed up. This is purposefully done
to ensure that it is regularly recycled and that anything used to build the
infrastructure is captured and automated.

More details on the Chef server and how to use it can be found in the README
with the Dockerfile.

### Installing Docker

Like all good things, installing Docker is an extremely complex and time-
consuming process, on OS X you can use [Homebrew](homebrew) to install both the
docker-machine and docker client binaries:

    brew install docker-machine
    brew install docker

OK, maybe it isn't that difficult...




sudo ifconfig lo0 alias 10.254.254.254
sudo route -n add 172.17.0.0/16 (docker-machine ip)

To ~/.ssh/config
Host *.dev
  User kitchen
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
