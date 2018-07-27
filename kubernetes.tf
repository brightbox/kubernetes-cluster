# Computed variables
locals {
  validity_period    = 8760
  default_apiurl     = "https://api.${var.region}.brightbox.com"
  generated_path     = "${path.root}/generated"
  template_path      = "${path.root}/templates"
  service_cidr = "172.30.0.0/16"
  cluster_cidr = "192.168.0.0/16"
  boot_token         = "${random_string.token_prefix.result}.${random_string.token_suffix.result}"
}

provider "brightbox" {
  version  = "~> 1.0"
  apiurl   = "${local.default_apiurl}"
  username = "${var.username}"
  password = "${var.password}"
  account  = "${var.account}"
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

