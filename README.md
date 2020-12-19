# Torchun_infra
Torchun Infra repository

# Lecture 5, homework 3

> Accessing isolated server with single ssh command

bastion_IP = 178.154.247.170

someinternalhost_IP = 10.130.0.23

##### Solution 1 (simple way): chained ssh
@ local machine:
  - `ssh -A -t appuser@BASTION_IP ssh appuser@SOMEINTERNALHOST_IP`

##### Solution 2 (hard way): port forwarding  [will not work because of NAT]
 log in to bastion host:
 `ssh -A appuser@BASTION_IP` where -A is to allow authentication forwarding
 - generate public key @bastion server:
 $ `ssh-keygen`
 - copy generated ~/.ssh/id_rsa.pub to someinternalhost:
 $ `ssh-copy-id ~/.ssh/id_rsa.pub appuser@SOMEINTERNALHOST_IP`
 - generate publick key @someinternalhost server:
 `ssh-keygen`
 - get `id_rsa.pub` to bastion host:
 @bastion `scp appuser@SOMEINTERNALHOST_IP:~/.ssh/id_rsa.pub ~/.ssh/someinternalhost.pub`
 - add key to ~/.ssh/authorized_keys:
 `cat ~/.ssh/someinternalhost.pub >> ~/.ssh/authorized_keys`
 Ok, now login to @someinternalhost and create reverse ssh tunnel (e.g. use "screen"):
 - `ssh -A -R 22222:127.0.0.1:22 appuser@BASTION_PUBLIC_IP`
 Now you should be able to connect from local machine:
 - `ssh -A -p 22222 appuser@BASTION_PUBLIC_IP`
In lab it would not work, BASTION_PUBLIC_IP not accessible because of Yandex NAT.


> Accessing isolated server with "ssh someinternalhost" style

#### Solution: ~/.ssh/config
Put `ssh -A -t appuser@BASTION_PUBLIC_IP ssh appuser@SOMEINTERNALHOST_IP` to file `~/.ssh/config` in appropriate format:
```
  Host someinternalhost
    Hostname BASTION_PUBLIC_IP
    Port 22
    User appuser
    IdentityFile ~/.ssh/id_rsa.pub
    RequestTTY force
    ForwardAgent yes
    RemoteCommand ssh appuser@SOMEINTERNALHOST_IP
```
@local machine:
`ssh someinternalhost`


> Install Pritunl

#### Solution:
First, install iptables @bastion: `sudo apt-get install iptables`
All other stuff as described in homework.pdf


> Add ssl cert to prevent "untrusted" error
#### Solution
Go to https://sslip.io/ and check default DNS for IP: `dig +short 178-154-247-170.sslip.io`<br>
Go to `178-154-247-170.sslip.io` -> Settings -> Let's Encrypt Domain: enter here your default DNS: "178-154-247-170.sslip.io"<br>
Done!


# Lecture 6, homework 4

> Create ya.cloud VM with "yc" and deploy test app in it

testapp_IP = 178.154.246.238

testapp_port = 9292

##### Solution
@ local machine: as in pdf.

> create startup script to be executed on initial startup

##### Solution: use cloud-init script (yaml)
Examples shown in video. Additional info: https://www.digitalocean.com/community/tutorials/how-to-use-cloud-config-for-your-initial-server-setup
  - create yaml file with needed config, e.g. `metadata.yaml`
  - pass it while creating VM via `yc` command:
```
yc compute instance create \
  --name reddit-app \
  --hostname reddit-app \
  --memory=4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-1604-lts,size=10GB \
  --network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
  --metadata serial-port-enable=1 \
  --metadata-from-file user-data=./metadata.yaml
```

# Lecture 7 homework 5
> Making "Backed" image @ yandex.cloud with Packer.
##### Perform following steps:
Create service account @ yandex.cloud: \
`yc iam service-account create --name $SVC_ACCT --folder-id $FOLDER_ID`

Get account_id to variable: \
`ACCT_ID=$(yc iam service-account get $SVC_ACCT | grep ^id | awk '{print $2}')`

Give "editor" role to service account: \
`yc resource-manager folder add-access-binding --id $FOLDER_ID --role editor --service-account-id $ACCT_ID`\

Create key for service_account and store locally: \
`yc iam key create --service-account-id $ACCT_ID --output ~/secrets/yc/key.json`

Create two scripts to customize initial image:
 - `install_ruby.sh`
```
#!/usr/bin/env bash
apt update
apt install -y ruby-full ruby-bundler build-essential
```
 - `install_mongodb.sh`
```
#!/usr/bin/env bash
apt-get update
apt-get install apt-transport-https ca-certificates
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" \
| sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
apt-get update
apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod
systemctl status mongod --no-pager

```

Create `ubuntu16.json`:
```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "/full/path/to/secrets/yc/key.json",
            "folder_id": "aaaabbbbccccdddd",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```
Check if *<packer>*.json is correct: \
`packer validate ./ubuntu16.json`

And try to build image: \
`packer build ./ubuntu16.json `

#### Issue #1.
```
==> yandex: Error creating network: server-request-id = c035e0f4-e960-b8bf-a4b0
-c5bd61dc085b server-trace-id = 773200f7367e6ec5:ddfd944c93fa0f96:773200f7367e6
ec5:1 client-request-id = cd3ae657-fdc2-45d1-9205-c8be7c3e1baf client-trace-id
= cd2fd219-1142-461a-b7b4-0e9c506e0eb9 rpc error: code = ResourceExhausted desc
 = Quota limit vpc.networks.count exceeded
Build 'yandex' errored after 2 seconds 58 milliseconds: Error creating network:
 server-request-id = c035e0f4-e960-b8bf-a4b0-c5bd61dc085b server-trace-id = 7732
00f7367e6ec5:ddfd944c93fa0f96:773200f7367e6ec5:1 client-request-id = cd3ae657-fd
c2-45d1-9205-c8be7c3e1baf client-trace-id = cd2fd219-1142-461a-b7b4-0e9c506e0eb9
 rpc error: code = ResourceExhausted desc = Quota limit vpc.networks.count exceeded
```
=> Fix: remove all networks from current yandex folder
#### Issue #2.
```
==> yandex: Failed to find instance ip address: instance has no one IPv4 external address
Build 'yandex' errored after 1 minute 11 seconds: Failed to find instance ip address:
instance has no one IPv4 external address
```
=> Fix: [As in packer RTFM](https://www.packer.io/docs/builders/yandex.html#use_ipv4_nat) there is a need to allow NAT to internet: switch `use_ipv4_nat` to `true`:
```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "/full/path/to/secrets/yc/key.json",
            "folder_id": "aaaabbbbccccdddd",
            "source_image_family": "ubuntu-1604-lts",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "platform_id": "standard-v1",
            "use_ipv4_nat": "true"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```
#### Issue #3.
```
    yandex: Get:1 http://security.ubuntu.com/ubuntu xenial-security InRelease [109 kB]
    yandex: Err:2 http://mirror.yandex.ru/ubuntu xenial InRelease
    yandex:   Could not resolve 'mirror.yandex.ru'
    yandex: Err:3 http://mirror.yandex.ru/ubuntu xenial-updates InRelease
    yandex:   Could not resolve 'mirror.yandex.ru'
    yandex: Err:4 http://mirror.yandex.ru/ubuntu xenial-backports InRelease
    yandex:   Could not resolve 'mirror.yandex.ru'
    ...
    ==> yandex: W: Failed to fetch http://mirror.yandex.ru/ubuntu/dists/xenial-updates/InRelease
  Could not resolve 'mirror.yandex.ru'
    yandex: 84 packages can be upgraded. Run 'apt list --upgradable' to see them.
==> yandex: W: Failed to fetch http://mirror.yandex.ru/ubuntu/dists/xenial-backports/InRelease
  Could not resolve 'mirror.yandex.ru'
==> yandex: W: Some index files failed to download. They have been ignored,
 or old ones used instead.
```
=> Fix: manually add nameserver with first script mentioned in provisioners (scripts/install_ruby.sh), or ... see next issue.
#### Issue #4
```
==> yandex:
==> yandex: E: Could not get lock /var/lib/dpkg/lock-frontend - open (11: Resource temporarily unavailable)
==> yandex: E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), is another process using it?
```
=> Fix: No fix. Unattended upgrades triggered as VM starts, need to wait. Add some beauty: \
`install_ruby.sh`:
```
#!/usr/bin/env bash
echo "####### Installing Ruby: ${0} script START"
apt update && \
apt install -y ruby-full ruby-bundler build-essential
echo "####### Installing Ruby: ${0} script END"
exit 0

```
`install_mongodb.sh`:
```
#!/usr/bin/env bash
echo "####### Installing MongoDB: ${0} script START"
apt-get update && \
apt-get install apt-transport-https ca-certificates
wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.2 multiverse" \
 | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
apt-get update && \
apt-get install -y mongodb-org
systemctl start mongod
systemctl enable mongod
systemctl status mongod --no-pager
echo "####### Installing MongoDB: ${0} script END"
exit 0
```
Start VM using build image, and run app inside it:
```
sudo apt-get update
sudo apt-get install -y git
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
```
Then go to public IP:9292 and check web availability.

> Packer template for User Variables (variables.json): folder_id, source_image_family, service_account_key_file.
##### Solution:
Create variables.json and add mentioned variables:
```
{
  "folder_id": "aaaabbbbccccdddd",
  "source_image_family": "ubuntu-1604-lts",
  "service_account_key_file": "/full/path/to/secrets/yc/key.json",
  "disk_name": "reddit-fried",
  "disk_size_gb": "21"
}
```
And use it in `ubuntu16.json`:
```
{
    "builders": [
        {
            "type": "yandex",
            "service_account_key_file": "{{ user `service_account_key_file` }}",
            "folder_id": "{{ user `folder_id` }}",
            "source_image_family": "{{ user `source_image_family`}}",
            "image_name": "reddit-base-{{timestamp}}",
            "image_family": "reddit-base",
            "ssh_username": "ubuntu",
            "use_ipv4_nat": "true",
            "platform_id": "standard-v1",
            "disk_name": "{{ user `disk_name` }}",
            "disk_size_gb": "{{ user `disk_size_gb` }}"
        }
    ],
    "provisioners": [
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        },
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }
    ]
}
```
Now check & build (don't forget to remove all networks):
```
packer validate -var-file=./variables.json ./ubuntu16.json
packer build -var-file=./variables.json ./ubuntu16.json
```

> Build "baked" image with prepared app auto-start.
##### Solution:
Need to make *.json with provisioners -> set up and copy config file -> systemd unit -> autostart app like a service on startup.
1. Translate content of deploy.sh into immutable.json (copied from ubuntu16.json) to `privisioners` section:
```
#!/usr/bin/env bash
sudo apt install -y git
cd ~
git clone -b monolith https://github.com/express42/reddit.git
cd reddit && bundle install
puma -d
ps aux | grep puma
echo "Check http://PUBLIC_IP:9292/"

```
2. Create [puma.service file](https://github.com/puma/puma/blob/master/docs/systemd.md):
```
[Unit]
Description=Puma
After=network.target

[Service]
Type=simple
WorkingDirectory=/server/reddit
ExecStart=/usr/local/bin/puma
Restart=always

[Install]
WantedBy=multi-user.target

```
Add [file provisioner](https://www.packer.io/docs/provisioners/file):
```
{
  "type": "file",
  "source": "files/puma.service",
  "destination": "/tmp/puma.service"
}
```
3. Need to use [inline provisioner](https://www.packer.io/docs/provisioners/shell):
```
{
    "type": "shell",
    "inline": [
        "sudo mv /tmp/puma.service /etc/systemd/system/puma.service",
        "sudo apt update && sudo apt install -y git",
        "sudo mkdir -p /server",
        "sudo chmod 777 /server && cd /server",
        "git clone -b monolith https://github.com/express42/reddit.git",
        "cd /server/reddit && bundle install",
        "sudo systemctl daemon-reload && sudo systemctl start puma && sudo systemctl enable puma"
    ]
}
```
4. Validate & build:
```
packer validate -var-file=./variables.json ./immutable.json
packer build -var-file=./variables.json ./immutable.json
```

> Make script to start instance from custom image
##### Solution: Put one line with YC into `create-reddit-vm.sh`:
```
yc compute instance create \
	--name reddit-app \
	--hostname reddit-app \
	--memory=4 \
	--create-boot-disk name=reddit-full,size=19GB,image-id=abcdefjhijklmnopqrst123 \
	--network-interface subnet-name=default-ru-central1-a,nat-ip-version=ipv4 \
	--metadata serial-port-enable=1 \
	--ssh-key ~/.ssh/appuser.pub
```
