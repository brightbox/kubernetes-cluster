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
 # worker_name = "k8s-storage"
 # worker_zone = "b"

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

