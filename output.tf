output "apiserver" {
  value = module.k8s_master.apiserver
}

output "bastion" {
  value = module.k8s_master.bastion
}

output "controller_client" {
  value = brightbox_api_client.controller_client.id
}

output "controller_client_secret" {
  value = brightbox_api_client.controller_client.secret
}

output "apiurl" {
  value = "https://api.${var.region}.brightbox.com"
}

output "group_fqdn" {
  value = "${module.k8s_cluster.group_id}.${local.region_suffix}"
}

output "cluster_fqdn" {
  value = local.cluster_fqdn
}

