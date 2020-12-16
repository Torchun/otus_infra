#!/usr/bin/env bash
if [ $(whoami) != "yc-user" ]
  then echo "Please run as yc-user with sudoers permissions"
  exit 99
fi

wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod
systemctl status mongod --no-pager
