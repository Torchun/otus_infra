#!/usr/bin/env bash
sudo apt install -y git
cd ~
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
ps aux | grep puma
echo "Check http://PUBLIC_IP:9292/"
