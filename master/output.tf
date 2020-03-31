output "apiserver" {
  value       = local.public_ip
  description = "Publicly accessible apiserver address"
}

output "bastion" {
  value       = local.bastion
  description = "Publicly accessible host to use to configure masters from"
}

output "bastion_user" {
  value       = local.bastion_user
  description = "Logon ID on Bastion Host"
}

output "servers" {
  value       = brightbox_server.k8s_master
  description = "List of this modules brightbox servers"
}
