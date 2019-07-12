resource "null_resource" "spread_deployments" {

  depends_on = [
    null_resource.k8s_master_configure,
    null_resource.k8s_worker_configure,
    null_resource.k8s_master_mirrors_configure,
  ]

  connection {
    user = brightbox_server.k8s_master[0].username
    host = local.bastion
  }

  provisioner "remote-exec" {
    script = "${local.template_path}/spread-deployments"
  }

}
