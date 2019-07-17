resource "null_resource" "spread_deployments" {

  depends_on = [
    module.k8s_worker,
    null_resource.k8s_master_configure,
    null_resource.k8s_master_mirrors_configure,
  ]

  connection {
    user = local.bastion_user
    host = local.bastion
  }

  provisioner "remote-exec" {
    script = "${local.template_path}/spread-deployments"
  }

}
