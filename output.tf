output "master" {
  value = module.k8s_master.apiserver
}

output "bastion" {
  value = module.k8s_master.bastion
}

output "group_fqdn" {
  value = "${module.k8s_cluster.group_id}.${local.region_suffix}"
}

output "worker_ids" {
  value = module.k8s_worker.servers[*].id
}

output "storage_ids" {
  value = module.k8s_storage.servers[*].id
}

