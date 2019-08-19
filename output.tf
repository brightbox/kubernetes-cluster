output "master" {
  value = module.k8s_master.apiserver
}

output "bastion" {
  value = module.k8s_master.bastion
}

output "group_fqdn" {
  value = "${module.k8s_cluster.group_id}.${local.region_suffix}"
}

