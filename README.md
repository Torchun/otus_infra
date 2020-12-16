# Torchun_infra
Torchun Infra repository

### Lecture 5, homework 3

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


### Lecture 6, homework 4

> Create ya.cloud VM with "yc" and deploy test app in it

testapp_IP = 178.154.246.67

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
