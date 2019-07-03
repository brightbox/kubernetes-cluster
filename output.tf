output "master" {
  value = local.public_fqdn
}

output "group_fqdn" {
  value = "${brightbox_server_group.k8s.id}.${local.region_suffix}"
}

