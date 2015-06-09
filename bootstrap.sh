#!/bin/sh

# This will download and install all updates available for your Mac.
sudo softwareupdate -i -a

if [[ ! -d "$('xcode-select' -print-path 2>/dev/null)" ]]; then
  echo "Installing Xcode..."
  xcode-select --install
fi

if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  brew update
fi

brew tap Homebrew/bundle
brew bundle
brew upgrade -all
brew cleanup

which -s git || brew install git

git subtree add --prefix containers \
  http://github.com/riddopic/docker-containers master --squash

if [[ $SHELL = '/bin/bash' || $SHELL = '/usr/local/bin/bash' ]]; then
  echo "$(SHELL) shell detected"
  eval $(chef shell-init bash)

  if test ! $(grep "chef shell-init bash" ~/.bash_profile > /dev/null); then
    echo "Adding 'chef shell-init bash' to ~/.bash_profile"
    echo 'eval "$(chef shell-init bash)"' >> ~/.bash_profile
  fi
elif [[ $SHELL = '/bin/zsh' || $SHELL = '/usr/local/bin/zsh' ]]; then
  echo "$(SHELL) shell detected"
  eval $(chef shell-init zsh)

  if test ! $(grep "chef shell-init zsh" ~/.zshrc > /dev/null); then
    echo "Adding 'chef shell-init zsh' to ~/.zshrc"
    echo 'eval "$(chef shell-init zsh)"' >> ~/.zshrc
  fi
fi

bundle install

docker-machine create -d vmwarefusion \
  --vmwarefusion-memory-size 4096 \
  --vmwarefusion-disk-size 40000 \
  --vmwarefusion-boot2docker-url https://github.com/boot2docker/boot2docker/releases/download/v1.6.2/boot2docker.iso dev

# Create a route entry to the container network:
sudo route -n add 172.17.0.0/16 $(docker-machine ip)

# Create an alias on our loopback interface with a fixed IP.
sudo ifconfig lo0 alias 10.254.254.254

# TODO: THis is a very weak check
if test ! $(grep "acme.dev" ~/.ssh/config > /dev/null); then
  tee ~/.ssh/config >/dev/null <<EOF
Host *.acme.dev
  User kitchen
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
EOF
fi
