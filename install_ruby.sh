#!/usr/bin/env bash
if [ $(whoami) != "yc-user" ]
  then echo "Please run as yc-user with sudoers permissions"
  exit 99
fi

sudo apt update
sudo apt install -y ruby-full ruby-bundler build-essential
