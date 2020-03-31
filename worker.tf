module "k8s_worker" {
  source = "./worker"

  #Dependencies
  cluster_ready = module.k8s_cluster

  #Variables
  root_size             = var.worker_root_size
  worker_count          = var.worker_count
  worker_max            = max(var.worker_max, var.worker_count)
  worker_type           = var.worker_type
  image_desc            = var.image_desc
  region                = var.region
  internal_cluster_fqdn = local.cluster_fqdn
  worker_name           = var.worker_name
  worker_zone           = var.worker_zone

  #Injections
  cluster_server_group = module.k8s_cluster.group_id
  bastion              = module.k8s_master.bastion
  bastion_user         = module.k8s_master.bastion_user
}

module "k8s_storage" {
  source = "./worker"

  #Dependencies
  cluster_ready = module.k8s_cluster

  #Variables
  root_size             = var.storage_root_size
  worker_count          = var.storage_count
  worker_max            = max(var.storage_max, var.storage_count)
  worker_type           = var.storage_type
  image_desc            = var.image_desc
  region                = var.region
  internal_cluster_fqdn = local.cluster_fqdn
  worker_name           = var.storage_name
  worker_zone           = var.storage_zone

  #Injections
  cluster_server_group = module.k8s_cluster.group_id
  bastion              = module.k8s_master.bastion
  bastion_user         = module.k8s_master.bastion_user
}

