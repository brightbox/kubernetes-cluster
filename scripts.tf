locals {
  worker_cloud_config = file("${local.template_path}/cloud-config.yml")
  master_cloud_config = file("${local.template_path}/cloud-config.yml")

  install_provisioner_script = templatefile(
    "${local.template_path}/install-kube",
    { kubernetes_release = var.kubernetes_release }
  )

  storage_class_provisioner_script = templatefile(
    "${local.template_path}/define-storage-class",
    { storage_reclaim_policy = var.reclaim_volumes ? "Delete" : "Retain" }
  )

  master_provisioner_script = templatefile("${local.template_path}/install-master", {
    kubernetes_release       = var.kubernetes_release,
    calico_release           = var.calico_release,
    cluster_name             = var.cluster_name,
    public_ip                = local.public_ip,
    public_fqdn              = local.public_fqdn,
    service_cluster_ip_range = local.service_cidr,
    controller_client        = brightbox_api_client.controller_client.id,
    controller_client_secret = brightbox_api_client.controller_client.secret,
    apiurl                   = "https://api.${var.region}.brightbox.com",
    service_port             = local.service_port,
    }
  )

  kubeadm_config_script = templatefile(
    "${local.template_path}/kubeadm-config",
    {
      kubernetes_release     = var.kubernetes_release,
      cluster_name           = var.cluster_name,
      cluster_domainname     = var.cluster_domainname,
      service_cidr           = local.service_cidr,
      cluster_cidr           = local.cluster_cidr,
      public_ip              = local.public_ip,
      public_rdns            = local.public_rdns,
      public_fqdn            = local.public_fqdn,
      fqdn                   = local.fqdn,
      ipv6_fqdn              = local.ipv6_fqdn,
      boot_token             = local.boot_token,
      cluster_domainname     = var.cluster_domainname,
      hostname               = brightbox_server.k8s_master[0].hostname,
      master_certificate_key = random_id.master_certificate_key.hex,
      service_port           = local.service_port,
    }
  )

  worker_provisioner_script = templatefile(
    "${local.template_path}/install-worker",
    {
      kubernetes_release = var.kubernetes_release
      worker_vol_count   = var.worker_vol_count
      boot_token         = local.boot_token
      fqdn               = local.public_fqdn
      service_port       = local.service_port
    }
  )

  master_mirror_provisioner_script = templatefile("${local.template_path}/install-master-mirror", {
    kubernetes_release       = var.kubernetes_release,
    calico_release           = var.calico_release,
    cluster_name             = var.cluster_name,
    public_fqdn              = local.public_fqdn,
    service_cluster_ip_range = local.service_cidr,
    controller_client        = brightbox_api_client.controller_client.id,
    controller_client_secret = brightbox_api_client.controller_client.secret,
    apiurl                   = "https://api.${var.region}.brightbox.com",
    boot_token               = local.boot_token
    fqdn                     = local.public_fqdn
    master_certificate_key   = random_id.master_certificate_key.hex,
    service_port             = local.service_port
    }
  )
}
