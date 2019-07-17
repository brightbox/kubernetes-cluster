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

