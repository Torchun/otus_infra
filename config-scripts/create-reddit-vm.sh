#!/usr/bin/env bash
yc compute instance create \
	--name reddit-app \
	--hostname reddit-app \
	--memory=4 \
	--create-boot-disk name=reddit-full,size=19GB,image-id=fd8nscqjvcb3qpa7spl7 \
	--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
	--metadata serial-port-enable=1 \
	--ssh-key ~/.ssh/appuser.pub
