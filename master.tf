module "k8s_master" {
  source = "./master"
  #Dependencies
  cluster_ready = module.k8s_cluster

  #Variables
  master_count           = var.master_count
  master_type            = var.master_type
  image_desc             = var.image_desc
  region                 = var.region
  kubernetes_release     = var.kubernetes_release
  calico_release         = var.calico_release
  cluster_name           = var.cluster_name
  cluster_domainname     = var.cluster_domainname
  reclaim_volumes        = var.reclaim_volumes
  cluster_cidr           = local.cluster_cidr
  service_cidr           = local.service_cidr
  apiserver_service_port = local.service_port

  #Injections
  cluster_server_group    = module.k8s_cluster.group_id
  cluster_firewall_policy = module.k8s_cluster.firewall_policy_id
  ca_cert_pem             = tls_self_signed_cert.k8s_ca.cert_pem
  ca_private_key_pem      = tls_private_key.k8s_ca.private_key_pem
  install_script          = local.install_provisioner_script
  cloud_config            = local.cloud_config
}

