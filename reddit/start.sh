#!/bin/bash

# do not ignore any errors, exits immediately
set -e

echo "Starting MongoDB"
/usr/bin/mongod --fork --syslog
echo "MongoDB Started"


echo "start puma for reddit"
cd /app && puma || exit
