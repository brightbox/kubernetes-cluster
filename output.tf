output "master" {
  value = local.public_ip
}

output "bastion" {
  value = local.bastion
}

output "group_fqdn" {
  value = "${module.k8s_cluster.group_id}.${local.region_suffix}"
}

