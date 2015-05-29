
sudo ifconfig lo0 alias 10.254.254.254
sudo route -n add 172.17.0.0/16 (docker-machine ip)
