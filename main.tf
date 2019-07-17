# Computed variables
locals {
  validity_period = 8760
  region_suffix   = "${var.region}.brightbox.com"
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

resource "tls_private_key" "k8s_ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "k8s_ca" {
  key_algorithm   = tls_private_key.k8s_ca.algorithm
  private_key_pem = tls_private_key.k8s_ca.private_key_pem

  subject {
    common_name         = "apiserver"
    organizational_unit = local.cluster_fqdn
  }

  validity_period_hours = local.validity_period

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}

