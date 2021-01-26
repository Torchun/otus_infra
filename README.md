[![Build Status](https://travis-ci.com/Otus-DevOps-2020-11/Torchun_infra.svg?branch=main)](https://travis-ci.com/Otus-DevOps-2020-11/Torchun_infra)

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
# Lecture 8, homework 6

> Create LoadBalancer via terraform

##### Solution
@ lb.tf file describe [target group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_target_group):
```
resource "yandex_lb_target_group" "loadbalancer" {
  name      = "lb-group"
  folder_id = var.folder_id

  target {
    address = yandex_compute_instance.app.network_interface.0.ip_address
      subnet_id = var.subnet_id
  }
}
```
And describe LoadBalancer as in Terraform [docs](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lb_network_load_balancer):
```
resource "yandex_lb_network_load_balancer" "lb" {
  name = "loadbalancer"
  type = "external"

  listener {
    name        = "listener"
    port        = 80
    target_port = 9292

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.loadbalancer.id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 9292
      }
    }
  }
}

```
Add output var to `outputs.tf`:
```
output "loadbalancer_ip_address" {
  value = yandex_lb_network_load_balancer.lb.listener.*.external_address_spec[0].*.address
}
```
Now `terraform plan && terraform apply -auto-approve` and check LoadBalancer IP.

> Add second app instance to be accessible via LoadBalancer

##### Solution
@ `main.tf` add second instance resource:
```
resource "yandex_compute_instance" "app2" {
  name = "reddit-app2"
  ...
}
```
@ `lb.tf` add reddit-app2 to yandex_lb_target_group:
```
  target {
    address = yandex_compute_instance.app2.network_interface.0.ip_address
      subnet_id = var.subnet_id
  }
```
Change `outputs.tf`  to show all IPs for each app[*]:
```
output "external_ip_addresses_app" {
  value = yandex_compute_instance.app[*].network_interface.0.nat_ip_address
}
```
As a result, LoadBalancer should provide stable access to endpoint app regardless of [one of] instance availability.

> Need to DRY Terraform config files

 - add instance count variable to `variables.tf` and `terraform.tfvars`
 - rename all app instances to be named with changing number in `main.tf`
 - change LoadBalancer target group dynamically

1. In `variables.tf` add:
```
variable instance_count{
  description = "Number of instances to be created"
  # set default value to 1
  default     = 1
}

```
To `terraform.tfvars` append:
```
instance_count           = 2
```
2. Change `main.tf` to create instances with [reserverd word "count" to make loop](https://www.terraform.io/docs/configuration/meta-arguments/count.html) with unique names and IPs with
replacing `yandex_compute_instance.app.` -> `self.`:
```
  count = var.instance_count
  name = "reddit-app-${instance.index}"
  ...
    host  = self.network_interface.0.nat_ip_address
```
3. Using Terraform [dynamic block](https://www.terraform.io/docs/configuration/expressions/dynamic-blocks.html) annotation, in `lb.tf` create "loop" over instances IPs to place it in "target". Previous target descriptions should be removed:
```
  dynamic "target" {
    for_each = yandex_compute_instance.app.*.network_interface.0.ip_address
    content {
      subnet_id = var.subnet_id
      address   = target.value
    }
  }
```
4. Double-check: `terraform plan && terraform apply -auto-approve`

# Lecture 9, homework 7

> Perform steps in PDF to play with resource dependencies

##### Solution
As described

> Split one image to two: ubuntu16.json to app.json + db.json
##### Solution
```
cd ../packer
cp ubuntu16.json app.json
cp ubuntu16.json db.json
```
Fix `app.json` and `db.json` to contain only relevant part of provisioners, and after build packer images:
`app.json`:
```
            "image_name": "reddit-app-base-{{timestamp}}",
            "image_family": "reddit-app-base",
...
        {
            "type": "shell",
            "script": "scripts/install_ruby.sh",
            "execute_command": "sudo {{.Path}}"
        }


```
`db.json`:
```
            "image_name": "reddit-db-base-{{timestamp}}",
            "image_family": "reddit-db-base",
...
        {
            "type": "shell",
            "script": "scripts/install_mongodb.sh",
            "execute_command": "sudo {{.Path}}"
        }

```
Now build images:
```
packer validate -var-file=./variables.json ./app.json
packer build -var-file=./variables.json ./app.json
packer validate -var-file=./variables.json ./db.json
packer build -var-file=./variables.json ./db.json
```
> Split one main.tf to two: app.tf and db.tf
##### Solution
1. Append to `variables.tf`:
```
variable app_disk_image {
  description = "Disk image for reddit app"
  default = "reddit-app-base"
}
variable db_disk_image {
  description = "Disk image for reddit db"
  default = "reddit-db-base"
}
```
2. Append to `terraform.tfvars`:
```
app_disk_image            = "reddit-app-base" # change to your fd8gulo0dtv9uu8oqhoi
db_disk_image             = "reddit-db-base" # change to your fd8olmief7lme71b4ud5
```
3. `app.tf`:
```
resource "yandex_compute_instance" "app" {
  name = "reddit-app"

  labels = {
    tags = "reddit-app"
  }
  resources {
    core_fraction = 5
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.app_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```
`db.tf`:
```
resource "yandex_compute_instance" "db" {
  name = "reddit-db"
  labels = {
    tags = "reddit-db"
  }

  resources {
    core_fraction = 5
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = var.db_disk_image
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    nat = true
  }

  metadata = {
  ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
```
`vpc.tf`:
```
resource "yandex_vpc_network" "app-network" {
  name = "reddit-app-network"
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = "reddit-app-subnet"
  zone           = "ru-central1-a"
  network_id     = "${yandex_vpc_network.app-network.id}"
  v4_cidr_blocks = ["192.168.10.0/24"]
}
```
Append to `outputs.tf`:
```
output "external_ip_address_app" {
  value = yandex_compute_instance.app.network_interface.0.nat_ip_address
}
output "external_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.nat_ip_address
}
```
> Use modules
##### Solution:
As described in PDF. Be careful and use `var.subnet_id` where needed!

`terraform destroy` after check

> Reuse modules in "Stage" and "Prod" envirinments
##### Solution:
As described in PDF. Check:
```
cd stage
terraform fmt
terraform init
terraform plan
terraform apply
terraform destroy

cd prod
terraform fmt
terraform init
terraform plan
terraform apply
terraform destroy
```
> Starred task #1: Store terraform.tfstate in remote backend (yandex.cloud s3)
##### Solution:
1. Check if you have service account @ yc:
```
yc iam service-account list --folder-id=<your_infra_folder> # odejnmett8ttu9pds437
```
2. Bucket used to store tfstate:
 - should be created before `terraform apply` inside any of `modules` directory
 - should be the same for each directory inside `modules`
 - should be destroyed after usage on `terraform destroy`
So there is a need to create `*.tf` with `variables.tf` and `terraform.tfvars`:
3. First, [generate one-time secret and key](https://cloud.yandex.ru/docs/iam/operations/sa/create-access-key) with `yc iam access-key list --service-account-name terraform --folder-id=b1gke8b3gh5mjbpt1asr`:
 - `key_id: IsIs0huFkJF5PGIfxGUc`
 - `secret: CGh9qIjFdPNU6Kd7GYq3d1IWLALpOYazCj0sXgQ3`

@ terraform' root directory:

Copy from [prod|stage] and append to `variables.ft`:
```
### Add S3 creds here
variable yabucket_key_id {
  description = "key_id for yandex s3"
}
variable yabucket_secret {
  description = "secret for yandex s3"
}
variable bucket_name {
  description = "Yandex bucket name"
}
```
Copy from [prod|stage] and append to `terraform.tfvars`:
```
yabucket_key_id          = "IsIs0huFkJF5PGIfxGUc"
yabucket_secret          = "CGh9qIjFdPNU6Kd7GYq3d1IWLALpOYazCj0sXgQ3"
bucket_name              = "terraform-2"
```
Create `yandex_bucket.tf` as described [here](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/storage_bucket) and [here](https://cloud.yandex.ru/docs/solutions/infrastructure-management/terraform-state-storage):
```
provider "yandex" {
  version                  = "~> 0.35.0"
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_storage_bucket" "tfstate" {
  bucket        = var.bucket_name
  access_key    = var.yabucket_key_id
  secret_key    = var.yabucket_secret
  force_destroy = "true"
}
```
Now test if bucket being created: `terraform plan` and if Ok, `terraform apply`

Place `backend.tf` in each of [prod|stage] [with content](https://cloud.yandex.com/docs/solutions/infrastructure-management/terraform-state-storage):
```
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket   = "<bucket name>"
    region     = "us-east-1"
    key = "<path to the state file in the bucket>/<state file name>.tfstate"
    access_key = "<static key identifier>"
    secret_key = "<secret key>"

    skip_region_validation      = true
    skip_credentials_validation = true
  }
}
```
E.g. for prod (same content for stage):
```
terraform {
  backend "s3" {
    endpoint   = "storage.yandexcloud.net"
    bucket     = "terraform-2"
    region     = "ru-central1-a"
    key        = "terraform.tfstate"
    access_key = "IsIs0huFkJF5PGIfxGUc"
    secret_key = "CGh9qIjFdPNU6Kd7GYq3d1IWLALpOYazCj0sXgQ3"


    skip_region_validation      = true
    skip_credentials_validation = true
   }
}

```
Don't forget co copy to [prod|stage].

> Add provisioners to [prod|stage] to run app as supposed.
##### Solution: add files and provisioners to modules [app]
1. `mkdir -p modules/app/files; mkdir -p modules/db/files`
2. `cp files/puma.service modules/app/files/puma.service`
3. Insert to puma.service:
```
...
[Service]
Type=simple
User=ubuntu
Environment=DATABASE_URL=${DB_IPADDR}
...
```
4. Add provisioner to [app] main.tf:
```
  connection {
    type  = "ssh"
    host  = yandex_compute_instance.app.network_interface[0].nat_ip_address
    user  = "ubuntu"
    agent = false
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
  # need to describe in variables.tf and get from DB instance
    content     = templatefile("${path.module}/files/puma.service", { DB_IPADDR = var.db_ipaddr})
    destination = "/tmp/puma.service"
  }
  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
```
5. Describe DB_IPADDR in `variables.tf`:
```
variable db_ipaddr {
  description = "Database IP address"
}
```
In [prod|stage] `main.tf`:
```
module "app" {
  source          = "../modules/app"
  public_key_path = var.public_key_path
  app_disk_image  = var.app_disk_image
  subnet_id       = var.subnet_id
  private_key_path = var.private_key_path
  db_ipaddr       = module.db.internal_ip_address_db

}
```
In [modules] `db/outputs.tf`:
```
output "internal_ip_address_db" {
  value = yandex_compute_instance.db.network_interface.0.ip_address
}
```
Try to apply. Should be ok.
##### Issue #1: Web check to app IP shows there is no access to MongoDB.
=> Fix: need to specify IP on which MongoDB should start.
1. Create [MongoDB config file](https://docs.mongodb.com/manual/reference/configuration-options/) in modules/db/files/mongod.conf:
```
systemLog:
  destination: file
  path: "/var/log/mongodb/mongod.log"
  logAppend: true
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true
net:
  bindIp: ${db_ipaddr}
  port: 27017
```
2. Place restarting script to [db] module to modules/db/files/deploy.sh:
```
#!/usr/bin/env bash

sudo mv -f /tmp/mongod.conf /etc/mongod.conf
sudo systemctl restart mongod
```
3. Add provisioner to [db] instance in modules/db/main.tf:
```
...
  connection {
    type  = "ssh"
    host  = yandex_compute_instance.db.network_interface[0].nat_ip_address
    user  = "ubuntu"
    agent = false
    # путь до приватного ключа
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
    content     = templatefile("${path.module}/files/mongod.conf", { db_ipaddr = yandex_compute_instance.db.network_interface.0.ip_address})
    destination = "/tmp/mongod.conf"
  }
  provisioner "remote-exec" {
    script = "${path.module}/files/deploy.sh"
  }
...
```
Now check:
 - `terraform destroy`
 - `terraform plan`
 - `terraform apply`
Go to app IP:9292 to be sure everything working.

# Lecture 10, homework 8

> Perform steps in PDF to play with resource dependencies

##### Solution
As described

> Make inventory.json dynamic

##### Solution
Using [dynamic inventory description](https://nklya.medium.com/%D0%B4%D0%B8%D0%BD%D0%B0%D0%BC%D0%B8%D1%87%D0%B5%D1%81%D0%BA%D0%BE%D0%B5-%D0%B8%D0%BD%D0%B2%D0%B5%D0%BD%D1%82%D0%BE%D1%80%D0%B8-%D0%B2-ansible-9ee880d540d6) there is a need to create special script and use it as part of `ansible` commands, e.g. described in `ansible.cfg`.
At first step, create empty file with `touch inventory.sh`.

According to [inventory scripts guide](https://docs.ansible.com/ansible/latest/dev_guide/developing_inventory.html#developing-inventory-scripts), inventory script should accept `--list` and `--host` args. `--host` allowed to return empty json. So basically there is a need to create inventory script which accept `--list` arg and return json to STDOut. This script should be mentioned in `ansible.cfg`:
```
[defaults]
inventory = ./inventory.py
...

[inventory]
enable_plugins = script
```

Need to get names and IPs for running instances:
```
$ yc compute instances list
+----------------------+------------+---------------+---------+----------------+-------------+
|          ID          |    NAME    |    ZONE ID    | STATUS  |  EXTERNAL IP   | INTERNAL IP |
+----------------------+------------+---------------+---------+----------------+-------------+
| fhmgve9uhhothfn8uqh6 | reddit-app | ru-central1-a | RUNNING | 84.201.173.174 | 10.130.0.11 |
| fhmohhoj9gb1r92chh54 | reddit-db  | ru-central1-a | RUNNING | 84.201.173.51  | 10.130.0.15 |
+----------------------+------------+---------------+---------+----------------+-------------+

$ yc compute instances list | grep "|" | grep -v "STATUS" | awk -F\| '{print $3}'
 reddit-app
 reddit-db

yc compute instances list | grep "|" | grep -v "STATUS" | awk -F\| '{print $6}'
 84.201.173.174
 84.201.173.51

```
And place it into Python script:
```
#!/usr/bin/env python3
import sys
import subprocess
import json

# set default STDout
if len(sys.argv) > 1:
    if sys.argv[1] == "--host":
        print('{"_meta": {"hostvars": {}}}')
        sys.exit()
    if sys.argv[1] != "--list":
        print('{}')
        sys.exit()
else:
    print("--list | --host | ...")
    sys.exit(99)

result = subprocess.run(['yc','compute', 'instances', 'list'], stdout=subprocess.PIPE).stdout.decode('utf-8')

# keep only instance lines
instance_line = []
for line in result.rstrip('\n').split("\n"):
    if "|" in line and "STATUS" not in line:
        instance_line.append(line)

# making list of instances
instance = []
for j in instance_line:
    j = j.split()
    while "|" in j: j.remove("|")
    instance.append({"host": j[1], "ip": j[4]})

# creating groups
all_group = []
app_group = []
db_group = []
for i in instance:
    if "-app" in i["host"]:
        app_group.append(i["ip"])
    if "-db" in i["host"]:
        db_group.append(i["ip"])
    all_group.append(i["ip"])
_meta = {"hostvars": {}}

# fullfil response:
response = {}
response["app"] = {"hosts": app_group}
response["db"] = {"hosts": db_group}
response["all"] = {"hosts": all_group}
response["_meta"] = {"hosts": _meta}

print(json.dumps(response, sort_keys=True, indent=4))
sys.exit(0)

```
And place script output to json file `./inventory.py --list > inventory.json`

Run it as `ansible all -m ping`. Success!

# Lecture 11, homework 9

> Instance config management with Ansible
##### Solution
As described in PDF. Take into account that `puma` installed with `bundle install` _after_ `git clone`. Simplest way is to make next change in `site.yml` after splitting __reddit_app2.yml__ into three files __app.yml, db.yml, deploy.yml__:
```
---
- import_playbook: db.yml
- import_playbook: deploy.yml # <-- this goes first to install puma
- import_playbook: app.yml
```

> Dynamic inventory
##### Solution
Re-use inventory.py from previous HW with modification: need to pass `db_ipaddr` to ansble' YAML:
1. Pass additional var to selected group of instances in `inventory.py`:
```
...
response["app"] = {"hosts": app_group, "vars":{"db_ipaddr": db_group[0]}}
response["db"] = {"hosts": db_group, "vars":{"db_ipaddr": db_group[0]}}
...
```
2. Change vars section in `app.yml`:
```
  vars:
#   db_host: 84.201.173.51
   db_host: "{{ db_ipaddr }}"
```
3. Don't forget to change `ansible.cfg` to use proper inventory (static or script):
```
[defaults]
#inventory = ./inventory
inventory = ./inventory.py
remote_user = ubuntu
private_key_file = ~/.ssh/ubuntu
host_key_checking = False
retry_files_enabled = False

[inventory]
enable_plugins = script
```
Check with `ansible-playbook site.yml --check` and re-run without `--check` if fails: puma may be not installed.

##### Hint #1: don't forget to add https pkgs to `packer_db.yml` to be able to get key:
```
  - name: install https and certs pkgs to be able to add key
    apt:
      name:
        - apt-transport-https
        - ca-certificates
      update_cache: yes
      state: present
```
##### Hint #2: don't forget about unattended updates after instance first start. Modify yml's, e.g. as in `deploy.yml` at first apt task:
```
 tasks:
    - name: install git
      become: yes
      apt: name=git state=present
      retries: 10
      delay: 10 # in seconds
      register: result
      until: result is not failed
#    - debug:
#        msg: "{{result}}"
#
#        "msg": {
#          "cache_update_time": 1609237469,
#          "cache_updated": false,
#          "changed": false,
#          "failed": false
#        }
```

# Lecture 12, homework 10

> Refactor app.yml and db.yml to Roles
##### Solution
As described in PDF.
Hint: do not use dynamic inventory right now (see starred tasks).

> Configure community role

As described in PDF.

Hint: do not waste time on opening port 80 in Terraform - just skip that

> Working with Ansible Vault

As described in PDF.

Hint: rebuild Terraform stage (or prod).

> Travis CI for Ansible/Terraform/Packer ckeck (linters). Configuring repo's `.travis.yml`

As [described here](https://nklya.medium.com/%D0%BB%D0%BE%D0%BA%D0%B0%D0%BB%D1%8C%D0%BD%D0%BE%D0%B5-%D1%82%D0%B5%D1%81%D1%82%D0%B8%D1%80%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D0%B5-%D0%B2-travisci-2b5ef9adb16e) install `trytravis` to perform tests without push to main repo. But [as said here](https://github.com/sethmlarson/trytravis) trytravis is not supported anymore. Sorry, but I will test with a lot of pushes to otus repo :)

UPD: Travis CI not working at all. Will try to guess. Added commands to `.travis.yml`
> Add badge to README.md with build status

Probably won't work too. Add to first line in README.md link to image with build status [from here](https://travis-ci.com/github/Otus-DevOps-2020-11/Torchun_infra)

# Lecture 13, homework 11

> Install Vagrant, create Vagrantfile, run two instances on local host
##### Solution
As described in PDF.
##### Hint 1:
Do not use dynamic inventory! Need to comment `enable_plugins` @ `ansible.cfg`:
```
...
[inventory]
# enable_plugins = script

```
##### Hint 2:
If starred task with `~/.ssh/config` has been done, remove this file, e.g. `mv ~/.ssh/config ~/.ssh/config.bckp`

##### Hint 3:

At `roles/db/tasks/install_mongo.yml` change APT key and update cache after adding repo:
```
- name: Add APT key
  apt_key:
    url: https://www.mongodb.org/static/pgp/server-3.2.asc
    state: present
  tags: install
```
... after adding repo ...
```
- name: update cache
  apt:
    update_cache: yes
  tags: install
```
... and then install ...
> Modify Vagrantfile to proxy nginx to 80 port

At `Vagrantfile` modify:
```
      ansible.extra_vars = {
        "deploy_user" => "vagrant",
        nginx_sites: {
          default: ["listen 80", "server_name 'reddit'", "location / {proxy_pass http://127.0.0.1:9292;}"]
        }
      }
```
> Additional tasks: testing if DB listens on port 27017

Append to `molecule/default/tests/test_default.py`:
```
# check 27017 port
def test_mongo_port(host):
    socket = host.socket('tcp://0.0.0.0:27017')
    assert socket.is_listening
```
> Additional tasks: use Ansible roles to build images with Paker

Change `packer/app.json`:
```
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/playbooks/packer_app.yml",
            "extra_arguments": ["--tags","ruby"],
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
        }
    ]
```
And `packer/db.json`:
```
    "provisioners": [
        {
            "type": "ansible",
            "playbook_file": "ansible/playbooks/packer_db.yml",
            "extra_arguments": ["--tags","install"],
            "ansible_env_vars": ["ANSIBLE_ROLES_PATH={{ pwd }}/ansible/roles"]
        }
    ]
```
Don't forget to link roles in `ansible/playbooks/packer_app.yml`:
```
  roles:
    - app
```
and in `ansible/playbooks/packer_db.yml`:
```
  roles:
    - db
```
Recreate images with packer (from repo' root dir):
```
packer build -var-file=./packer/variables.json ./packer/app.json
packer build -var-file=./packer/variables.json ./packer/db.json
```
Done.
