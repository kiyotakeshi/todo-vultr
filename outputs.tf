output "instance_id" {
  value = vultr_instance.todo.id
}

output "vcpu" {
  value = vultr_instance.todo.vcpu_count
}

output "ram" {
  value = vultr_instance.todo.ram
}

output "disk" {
  value = vultr_instance.todo.disk
}

output "instance_ipv4_address" {
  value = vultr_instance.todo.main_ip
}

output "os" {
  value = vultr_instance.todo.os
}

output "date_created" {
  value = vultr_instance.todo.date_created
}
