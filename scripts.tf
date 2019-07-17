locals {
  cloud_config = file("${local.template_path}/cloud-config.yml")

  install_provisioner_script = templatefile(
    "${local.template_path}/install-kube",
    { kubernetes_release = var.kubernetes_release }
  )

}
