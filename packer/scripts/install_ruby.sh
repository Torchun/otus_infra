#!/usr/bin/env bash
echo "####### Installing Ruby: ${0} script START"

# added to resolve mirror.yandex.ru
echo "nameserver 8.8.8.8" >> /etc/resolv.conf && \
apt update && \
apt install -y ruby-full ruby-bundler build-essential
echo "####### Installing Ruby: ${0} script END"
exit 0
