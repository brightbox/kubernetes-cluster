module "k8s_worker" {
  source = "./worker"
  #Dependencies
  server_groups   = [module.k8s_cluster.group_id]
  master_ready    = null_resource.k8s_master_configure
  cluster_ready    = module.k8s_cluster

  #Variables
  worker_count       = var.worker_count
  worker_vol_count   = var.worker_vol_count
  worker_type        = var.worker_type
  image_desc         = var.image_desc
  region             = var.region
  kubernetes_release = var.kubernetes_release

  #Injections
  internal_cluster_fqdn  = local.cluster_fqdn
  bastion                = local.bastion
  bastion_user           = local.bastion_user
  apiserver_fqdn         = local.public_ip
  apiserver_service_port = local.service_port
  worker_drain_timeout   = var.worker_drain_timeout
  ca_cert_pem            = tls_self_signed_cert.k8s_ca.cert_pem
  install_script         = local.install_provisioner_script
  cloud_config           = local.worker_cloud_config
  kubeadm_config_script  = local.kubeadm_config_script
}

