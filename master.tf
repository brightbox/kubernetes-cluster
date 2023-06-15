module "k8s_master" {
  source = "./master"
  #Dependencies
  cluster_ready = module.k8s_cluster

  #Variables
  master_count           = var.master_count
  master_type            = var.master_type
  image_desc             = var.image_desc
  region                 = var.region
  container_registry     = var.container_registry
  kubernetes_release     = var.kubernetes_release
  critools_release       = var.critools_release
  calico_release         = var.calico_release
  autoscaler_release     = var.autoscaler_release
  cluster_name           = var.cluster_name
  cluster_domainname     = var.cluster_domainname
  cluster_cidr           = local.cluster_cidr
  service_cidr           = local.service_cidr
  apiserver_service_port = local.service_port
  storage_system         = var.storage_system
  manage_autoscaler      = var.worker_max > var.worker_count || var.storage_max > var.storage_count
  master_zone            = var.master_zone
  secure_kubelet         = var.secure_kubelet

  #Injections
  cluster_server_group     = module.k8s_cluster.group_id
  cluster_firewall_policy  = module.k8s_cluster.firewall_policy_id
  ca_cert_pem              = tls_self_signed_cert.k8s_ca.cert_pem
  ca_private_key_pem       = tls_private_key.k8s_ca.private_key_pem
  additional_server_groups = var.additional_server_groups
}
