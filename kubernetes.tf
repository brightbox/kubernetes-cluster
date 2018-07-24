# Computed variables
locals {
  default_apiurl     = "https://api.${var.region}.brightbox.com"
  generated_path     = "${path.root}/generated"
  template_path      = "${path.root}/templates"
  service_ula_prefix = "${cidrsubnet("fdbf:726f::/32", 16, var.cluster_number)}"
  cluster_cidr       = "${cidrsubnet("fdc0:726f::/32", 16, var.cluster_number)}"
  service_cidr       = "${replace(local.service_ula_prefix, "/48", "/112")}"
}

provider "brightbox" {
  version  = "~> 1.0"
  apiurl   = "${local.default_apiurl}"
  username = "${var.username}"
  password = "${var.password}"
  account  = "${var.account}"
}

resource "random_integer" "service_cidr" {
  min = 0
  max = 4294967295
}

resource "random_integer" "cluster_cidr" {
  min = 1
  max = 65535
}

data "template_file" "install-provisioner-script" {
  template = "${file("${local.template_path}/install-kube")}"

  vars {
    k8s_release         = "${var.k8s_release}"
    critools_release    = "${var.critools_release}"
    cni_plugins_release = "${var.cni_plugins_release}"
    containerd_release  = "${var.containerd_release}"
    runc_release        = "${var.runc_release}"
    cluster_name        = "${var.cluster_name}"
    cluster_domainname  = "${var.cluster_domainname}"
    service_cidr        = "${local.service_cidr}"
    cluster_cidr        = "${local.cluster_cidr}"
    external_ip         = "${brightbox_server.k8s_master.ipv6_address}"
  }
}
