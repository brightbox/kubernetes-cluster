# Computed variables
locals {
  validity_period = 8760
  region_suffix   = "${var.region}.brightbox.com"
#  default_apiurl  = "https://api.${var.region}.brightbox.com"
  generated_path  = "${path.root}/generated"
  template_path   = "${path.root}/templates"
  service_cidr    = "172.30.0.0/16"
  cluster_cidr    = "192.168.0.0/16"
  boot_token      = "${random_string.token_prefix.result}.${random_string.token_suffix.result}"
  cluster_fqdn    = "${var.cluster_name}.${var.cluster_domainname}"
}

provider "brightbox" {
  version   = "~> 1.0"
  apiurl    = "https://api.${var.region}.brightbox.com"
  username  = "${var.username}"
  password  = "${var.password}"
  account   = "${var.account}"
  apiclient = "${var.apiclient}"
  apisecret = "${var.apisecret}"
}

provider "null" {
  version = "~> 2.0"
}

provider "random" {
  version = "~> 2.0"
}

provider "template" {
  version = "~> 2.0"
}

provider "tls" {
  version = "~> 1.2"
}

resource "random_string" "token_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "random_string" "token_prefix" {
  length  = 6
  special = false
  upper   = false
}
