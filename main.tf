# Computed variables
locals {
  validity_period = 8760
  region_suffix   = "${var.region}.brightbox.com"
  generated_path  = "${path.root}/generated"
  template_path   = "${path.root}/templates"
  service_cidr    = "172.30.0.0/16"
  cluster_cidr    = "192.168.0.0/16"
  cluster_fqdn    = "${var.cluster_name}.${var.cluster_domainname}"
  service_port    = "6443"
  cloud_config = file("${local.template_path}/cloud-config.yml")
  install_provisioner_script = templatefile(
    "${local.template_path}/install-kube",
    { kubernetes_release = var.kubernetes_release }
  )
}

provider "brightbox" {
  version   = "~> 1.2"
  apiurl    = "https://api.${var.region}.brightbox.com"
  username  = var.username
  password  = var.password
  account   = var.account
  apiclient = var.apiclient
  apisecret = var.apisecret
}

provider "null" {
  version = "~> 2.0"
}

provider "random" {
  version = "~> 2.0"
}

provider "tls" {
  version = "~> 2.0.1"
}

resource "null_resource" "spread_deployments" {

  depends_on = [
    module.k8s_worker,
    module.k8s_master,
  ]

  connection {
    user = module.k8s_master.bastion_user
    host = module.k8s_master.bastion
  }

  provisioner "remote-exec" {
    script = "${local.template_path}/spread-deployments"
  }

}
