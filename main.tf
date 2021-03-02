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
  # ssh_key_ids =
}
