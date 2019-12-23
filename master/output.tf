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

#output "kubeadm_config" {
#  value       = local.kubeadm_config_script
#  description = "Cluster kubeadm configuration manifest"
#}

output "apiserver_ready" {
  value       = local.masters_configured
  description = "Resource pre-requisite that signals the apiserver is ready"
}

output "boot_token" {
  value       = local.boot_token
  description = "Shared secret used by workers to connect to the control plane"
}
