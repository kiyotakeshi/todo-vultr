# @see https://registry.terraform.io/providers/vultr/vultr/latest/docs/resources/instance
# 1. create by management console
# 2. import `terraform import vultr_instance.todo df405601-c4b6-4de4-99b9-3e1a608876dc`
# 3. fill in .tf
resource "vultr_instance" "todo" {
  plan = "vc2-1c-1gb" # 5$/mo
  region = "nrt" # tokyo
  os_id = 362 # CentOS SELinux 8 x64
  activation_email = false
  backups = "disabled"
  ddos_protection = false
  enable_ipv6 = false
  enable_private_network = false
  hostname = local.app
  tag = local.app
  label = local.app
  # script_id =
  ssh_key_ids = [
    vultr_ssh_key.todo.id
  ]
}

resource "vultr_ssh_key" "todo" {
  name = local.app

  # ssh-keygen -m PEM -t rsa -b 2048 -f todo_key -C ""
  ssh_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClNT82nes7EFfJzf5ug/kpn4V8+DVh6i+MFFFMwqo7Zdl3lZ1FmXPq/iHpQblMH1BgupHgdwiGahu5unNGc/9Dn4uegUImsAReCcx826ISWKB59WyW5mBPvMZHr+uoWbtWAudEcY6xeO6MZjC1pepgxdIuzzcFi1LVNIi72bOzhq2IUibdNdqJsUPgUaqGyrfB+eyYhoTVHY7kH5/EdXMnbzw4S7tRXb9/X0MImCzOsjLjT/GOpDazuJChokJ0mqFx/A9tNTpsJ8r3n+PyIsnCywPGtOM9X4u3j8pSY+miFoZMYExYKi+jZDU9uei1xcpna/PZwYku2B5XAcf8xndV"
}