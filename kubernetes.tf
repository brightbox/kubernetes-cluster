provider "brightbox" {
  version  = "~> 1.0"
  apiurl   = "https://api.${var.region}.brightbox.com"
  username = "${var.username}"
  password = "${var.password}"
  account  = "${var.account}"
}

data "template_file" "install-provisioner-script" {
  template = "${file("${path.root}/templates/install-kube")}"

  vars {
    k8s_release                        = "${var.k8s_release}"
    critools_release                   = "${var.critools_release}"
    cni_plugins_release                = "${var.cni_plugins_release}"
    containerd_release                 = "${var.containerd_release}"
    runc_release                       = "${var.runc_release}"
    brightbox_cloud_controller_release = "${var.brightbox_cloud_controller_release}"
  }
}
