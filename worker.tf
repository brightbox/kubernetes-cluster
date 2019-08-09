module "k8s_worker" {
  source = "./worker"
  #Dependencies
  apiserver_ready = module.k8s_master.apiserver_ready
  cluster_ready   = module.k8s_cluster

  #Variables
  worker_count           = var.worker_count
  worker_type            = var.worker_type
  image_desc             = var.image_desc
  region                 = var.region
  kubernetes_release     = var.kubernetes_release
  internal_cluster_fqdn  = local.cluster_fqdn
  apiserver_service_port = local.service_port
  worker_drain_timeout   = var.worker_drain_timeout
  worker_name = var.worker_name
  worker_zone = var.worker_zone

  #Injections
  cluster_server_group  = module.k8s_cluster.group_id
  bastion               = module.k8s_master.bastion
  bastion_user          = module.k8s_master.bastion_user
  apiserver_fqdn        = module.k8s_master.apiserver
  ca_cert_pem           = tls_self_signed_cert.k8s_ca.cert_pem
  install_script        = local.install_provisioner_script
  cloud_config          = local.cloud_config
  kubeadm_config_script = module.k8s_master.kubeadm_config
}

module "k8s_storage" {
  source = "./worker"
  #Dependencies
  apiserver_ready = module.k8s_master.apiserver_ready
  cluster_ready   = module.k8s_cluster

  #Variables
  worker_count           = var.storage_count
  worker_type            = var.storage_type
  image_desc             = var.image_desc
  region                 = var.region
  kubernetes_release     = var.kubernetes_release
  internal_cluster_fqdn  = local.cluster_fqdn
  apiserver_service_port = local.service_port
  worker_drain_timeout   = var.worker_drain_timeout
  worker_name = var.storage_name
  worker_zone = var.storage_zone

  #Injections
  cluster_server_group  = module.k8s_cluster.group_id
  bastion               = module.k8s_master.bastion
  bastion_user          = module.k8s_master.bastion_user
  apiserver_fqdn        = module.k8s_master.apiserver
  ca_cert_pem           = tls_self_signed_cert.k8s_ca.cert_pem
  install_script        = local.install_provisioner_script
  cloud_config          = local.cloud_config
  kubeadm_config_script = module.k8s_master.kubeadm_config
}

