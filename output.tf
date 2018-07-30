output "master" {
  value = "${brightbox_server.k8s_master.*.fqdn}"
}

output "group_fqdn" {
  value = "${brightbox_server_group.k8s.id}.${local.region_suffix}"
}
