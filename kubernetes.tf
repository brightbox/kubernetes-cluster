# Computed variables
locals {
  default_apiurl = "https://api.${var.region}.brightbox.com"
  generated_path = "${path.root}/generated"
  template_path  = "${path.root}/templates"
}

provider "brightbox" {
  version  = "~> 1.0"
  apiurl   = "${local.default_apiurl}"
  username = "${var.username}"
  password = "${var.password}"
  account  = "${var.account}"
}

data "template_file" "install-provisioner-script" {
  template = "${file("${local.template_path}/install-kube")}"

  vars {
    k8s_release         = "${var.k8s_release}"
    critools_release    = "${var.critools_release}"
    cni_plugins_release = "${var.cni_plugins_release}"
    containerd_release  = "${var.containerd_release}"
    runc_release        = "${var.runc_release}"
  }
}
