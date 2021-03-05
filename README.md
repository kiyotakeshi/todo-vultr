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

## Create server from snapshot

```shell
vultr-cli snapshot list

vultr-cli instance create \
--snapshot "615aae20-2b4e-4d03-9131-fab98490df15" \
--region "nrt" --plan "vc2-1c-1gb"

vultr-cli instance list
```

---
## Deploy Todo application

- install and setup nginx

```shell
sudo su -

yum install -y nginx

# cat > /etc/nginx/default.d/reverse_proxy.conf <<EOF
location / {
    proxy_pass http://localhost:8081/;
    proxy_redirect off;
}
EOF

cp /etc/nginx/nginx.conf{,.old}

vi /etc/nginx/nginx.conf

# diff /etc/nginx/nginx.conf /etc/nginx/nginx.conf.old
46a47,49
>         location / {
>         }
>

systemctl start nginx

# systemctl is-active nginx
active

systemctl enable nginx

```

- install java

```shell
yum install -y java-11-openjdk

# java -version
openjdk version "11.0.9.1" 2020-11-04 LTS
OpenJDK Runtime Environment 18.9 (build 11.0.9.1+1-LTS)
OpenJDK 64-Bit Server VM 18.9 (build 11.0.9.1+1-LTS, mixed mode, sharing)
```

- install and setup postgresql

```shell
# dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

rpm -qi pgdg-redhat-repo

dnf module disable postgresql -y

dnf install postgresql11-server postgresql11 -y

postgresql-11-setup initdb

systemctl start postgresql-11

systemctl enable postgresql-11

su - postgres

psql

create database todo;

alter user postgres with password 'password';

\l

exit

cp /var/lib/pgsql/11/data/pg_hba.conf{,.old}

ls /var/lib/pgsql/11/data/pg_hba.conf*

vi /var/lib/pgsql/11/data/pg_hba.conf

# diff /var/lib/pgsql/11/data/pg_hba.conf /var/lib/pgsql/11/data/pg_hba.conf.old
82c82
< host    all             all             127.0.0.1/32            md5
---
> host    all             all             127.0.0.1/32            ident

systemctl restart postgresql-11
```

- transfer artifact o server

```shell
./mvnw clean package

scp -P 123456 -i todo-user.pem ~/todo/target/todo-1.1.1.jar todo@123.456.789.101:~/
```

- open firewall for http access

```shell
# firewall-cmd --permanent --zone public --add-service http
success

# firewall-cmd --reload
success

firewall-cmd --info-zone public
```

- permit reverse proxy nginx traffic
    - avoid following nginx error `failed (13: Permission denied) while connecting to upstream`

```shell
setsebool -P httpd_can_network_connect 1
```

## Run Application

```shell
nohup java -jar todo-1.1.1.jar &
```

## Set up TLS using Let's encrypt

```shell
dnf install epel-release

dnf install certbot python3-certbot-nginx

certbot certonly --nginx

certbot renew --dry-run

certbot certificates

# EOF までコピー
# cat > /etc/nginx/nginx.conf <<EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

# Load dynamic modules. See /usr/share/doc/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Load modular configuration files from the /etc/nginx/conf.d directory.
    # See http://nginx.org/en/docs/ngx_core_module.html#include
    # for more information.
    include /etc/nginx/conf.d/*.conf;

    server {

        # redirect http -> https
        if ($host = www.bullstechnology.com) {
            return 301 https://$host$request_uri;
        } # managed by Certbot

        listen       80 default_server;
        listen       [::]:80 default_server;
        server_name  localhost;
        root         /usr/share/nginx/html;

        # load reverse proxy related conf
        include /etc/nginx/default.d/*.conf;

        error_page 404 /404.html;
            location = /40x.html {
        }

        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }

# Settings for a TLS enabled server.
    server {
         server_name www.bullstechnology.com;
         root         /usr/share/nginx/html;
         listen [::]:443 ssl ipv6only=on;
         listen 443 ssl;
         ssl_certificate /etc/letsencrypt/live/www.bullstechnology.com/fullchain.pem;
         ssl_certificate_key /etc/letsencrypt/live/www.bullstechnology.com/privkey.pem;
         include /etc/letsencrypt/options-ssl-nginx.conf;
         ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

         # load reverse proxy related conf
         include /etc/nginx/default.d/*.conf;

         error_page 404 /404.html;
             location = /40x.html {
         }

         error_page 500 502 503 504 /50x.html;
             location = /50x.html {
         }
   }
}
EOF

# firewall-cmd --permanent --zone public --add-service https
success

# firewall-cmd --reload
success

systemctl restart nginx
```

---
## Delete component

- execute terraform

```shell
$ terraform destroy
```
