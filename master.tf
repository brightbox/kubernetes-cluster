module "k8s_master" {
  source = "./master"
  #Dependencies
  cluster_ready = module.k8s_cluster

  #Variables
  master_count           = var.master_count
  master_type            = var.master_type
  image_desc             = var.image_desc
  region                 = var.region
  internal_cluster_fqdn  = local.cluster_fqdn
  apiserver_service_port = local.service_port
  # master_zone = "b"

  #Injections
  cluster_server_group    = module.k8s_cluster.group_id
  cluster_firewall_policy = module.k8s_cluster.firewall_policy_id
}

