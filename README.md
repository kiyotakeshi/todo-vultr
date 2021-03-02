# Todo Vultr

## set up vultr-cli

- install vultr-cli using brew

```shell
brew tap vultr/vultr-cli

brew install vultr-cli
```

## check requirement id

```shell
export VULTR_API_KEY="ABCDEFGHIJ........"
```

- check region id

```shell
$ vultr-cli regions list | head -n 1
ID	CITY		COUNTRY		CONTINENT	OPTIONS

$ vultr-cli regions list | grep Tokyo
nrt	Tokyo		JP		Asia		[]
```

- check os id

```shell
$ vultr-cli os list | head -n 1
ID	NAME			ARCH	FAMILY

$ vultr-cli os list | grep -i "centos 8"
362	CentOS 8 x64		x64	centos
401	CentOS 8 Stream x64	x64	centos
```

## Create ssh key pair

```shell
ssh-keygen -m PEM -t rsa -b 2048 -f todo_key.pem -C ""

# using .pub key in main.tf
$ ls todo_key*
todo_key.pem	todo_key.pub
```

---
## Create component

- execute terraform

```shell
$ vi main.tf

$ terraform init

$ terraform plan

$ terraform apply
```

following output displayed

```shell
Apply complete! Resources: 0 added, 1 changed, 0 destroyed.

Outputs:

date_created = "2021-03-02T13:46:53+00:00"
disk = 25
instance_id = "5ccd6ba3-8377-452b-b988-73ce2caea720"
instance_ipv4_address = "12.34.567.890"
os = "CentOS SELinux 8 x64"
ram = 1024
vcpu = 1
```

- confirm instance is created

```shell
$ vultr-cli instance list

ID					IP		LABEL	OS	STATUS	Region	CPU	RAM	DISK	BANDWIDTH
abcdefgh-1234-5678-abcd-efghijklmnnp	12.34.567.890	todo	CentOS SELinux 8 x64	active	nrt	1	1024	25	1000
======================================
TOTAL	NEXT PAGE	PREV PAGE
1
```
---
## Setup Server

```shell
ssh -i todo_key.pem root@123.456.789.101

useradd todo

passwd todo
```

- cannot login as root user

```shell
$ vi /etc/ssh/sshd_config

     38 #PermitRootLogin yes
     39 PermitRootLogin no
```

- edit sudo config

```shell
visudo

    101 ## Same thing without a password
    102 # %wheel        ALL=(ALL)       NOPASSWD: ALL
         ### sudo実行時にパスワードを聞かれないように
    103  %wheel ALL=(ALL)       NOPASSWD: ALL
```

- add secondary group

```shell
usermod -G wheel todo 
```

- check todo user can use sudo

```shell
su - todo

$ id
uid=1000(todo) gid=1000(todo) groups=1000(todo),10(wheel) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023

sudo su -

# id
uid=0(root) gid=0(root) groups=0(root) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

- generate todo user ssh key pair

```shell
ssh-kengen

cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

chmod 400 /home/todo/.ssh/authorized_keys
```

- set no password login

```shell
sudo vi /etc/ssh/sshd_config

     64 #PasswordAuthentication yes
     65 PasswordAuthentication no
     66 #PermitEmptyPasswords no
```

- outputs and copy private key to access from local as todo user

```shell
less ~/.ssh/id_rsa
```

- restart sshd

```shell
systemctl restart sshd

# systemctl is-active sshd
active
```

**in local environment process**

- create todo-user private key in local env 

```shell
# copy todo user's id_rsa value cheked previous step
vi todo-user.pem

chmod 400 $_
```

- check NOT to be able to access server using root user

```shell
$ ssh -i todo_key.pem root@123.456.789.101
root@139.180.194.140: Permission denied (publickey,gssapi-keyex,gssapi-with-mic).
```

- check to be able to access server using todo user

```shell
ssh -i todo-user.pem todo@123.456.789.101

[todo@todo ~]$ id
uid=1000(todo) gid=1000(todo) groups=1000(todo),10(wheel) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

**in server process**

- change ssh port number

```shell
# set custom number
export CUSTOM_SSH_NUMBER=123456

sudo vi /etc/ssh/sshd_config

# tell port change to SELinux
$ sudo grep $CUSTOM_SSH_NUMBER /etc/ssh/sshd_config
Port 123456

sudo semanage port -a -t ssh_port_t -p tcp $CUSTOM_SSH_NUMBER

sudo systemctl restart sshd

$ sudo systemctl is-active sshd
active
```

- set firewalld

```shell
sudo cp /usr/lib/firewalld/services/ssh.xml /etc/firewalld/services/ssh-$CUSTOM_SSH_NUMBER.xml

sudo vi /etc/firewalld/services/ssh-$CUSTOM_SSH_NUMBER.xml

$ sudo grep $CUSTOM_SSH_NUMBER /etc/firewalld/services/ssh-$CUSTOM_SSH_NUMBER.xml
  <port protocol="tcp" port="123456"/>

# add firewalld config
$ sudo firewall-cmd --permanent --add-service=ssh-$CUSTOM_SSH_NUMBER
success

$ sudo firewall-cmd --reload
success

# check add
sudo firewall-cmd --list-services

# delete number 22 config
sudo firewall-cmd --permanent --remove-service=ssh

$ sudo firewall-cmd --reload
success

sudo firewall-cmd --list-services
```

**in local environment process**

- confirm ssh port changed

```shell
$ ssh -i todo-user.pem todo@123.456.789.101
ssh: connect to host 139.180.194.140 port 22: Connection refused

# can connect custom ssh port number
ssh -i todo-user.pem -p 123456 todo@123.456.789.101
```

**in server process**

- update

```shell
sudo yum update -y
```

**in local environment process**

- set .ssh/config

```shell
$ cat << EOF >> ~/.ssh/config
Host todo
  User todo
  Hostname 123.456.789.101
  IdentityFile ~/todo-user.pem
  Port 123456
EOF
```

```shell
ssh todo

# suceed to connect!
[todo@todo ~]$ uname -a
Linux todo 4.18.0-240.1.1.el8_3.x86_64 #1 SMP Thu Nov 19 17:20:08 UTC 2020 x86_64 x86_64 x86_64 GNU/Linux

[todo@todo ~]$ id
uid=1000(todo) gid=1000(todo) groups=1000(todo),10(wheel) context=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023
```

- take a snapshot

```shell
$ vultr-cli instance list

ID					IP		LABEL	OS	STATUS	Region	CPU	RAM	DISK	BANDWIDTH
abcdefgh-1234-5678-abcd-efghijklmnnp	12.34.567.890	todo	CentOS SELinux 8 x64	active	nrt	1	1024	25	1000
======================================
TOTAL	NEXT PAGE	PREV PAGE
1

vultr-cli snapshot create -i abcdefgh-1234-5678-abcd-efghijklmnnp -d "finish set ssh related conf up"

vultr-cli snapshot list
```

---
## Deploy Todo application

```shell
sudo su -

yum install git

git --version


```

---
## Delete component

- execute terraform

```shell
$ terraform destroy
```
