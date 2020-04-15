# Computed variables
locals {
  validity_period  = 87600
  renew_period     = 730
  region_suffix    = "${var.region}.brightbox.com"
  service_cidr     = "172.30.0.0/16"
  cluster_cidr     = "192.168.0.0/16"
  cluster_fqdn     = "${var.cluster_name}.${var.cluster_domainname}"
  service_port     = "6443"
  master_node_ids  = module.k8s_master.servers[*].id
  worker_node_ids  = module.k8s_worker.servers[*].id
  storage_node_ids = module.k8s_storage.servers[*].id
}

resource "brightbox_api_client" "controller_client" {
  name              = "Cloud Controller ${local.cluster_fqdn}"
  permissions_group = "full"
}
