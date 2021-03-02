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
ssh-keygen -m PEM -t rsa -b 2048 -f todo_key -C ""

# using .pub key in main.tf
$ ls todo_key*
todo_key	todo_key.pub
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
## Delete component

- execute terraform

```shell
$ terraform destroy
```
