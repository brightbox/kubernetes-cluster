locals {
  template_path = "${path.module}/templates"
  upgrade_script = templatefile(
    "${local.template_path}/upgrade-worker",
    { kubernetes_release = var.kubernetes_release }
  )
}

resource "brightbox_server_group" "k8s_worker_group" {
  name        = "${var.worker_name}.${var.internal_cluster_fqdn}"
  description = "${var.worker_count}:${var.worker_max}"
}

resource "brightbox_server" "k8s_worker" {
  depends_on = [
    var.cluster_ready,
    var.apiserver_ready,
  ]
  count = var.worker_count

  name  = "${var.worker_name}-${count.index}.${var.internal_cluster_fqdn}"
  image = data.brightbox_image.k8s_worker.id
  type  = var.worker_type
  user_data = templatefile(
    "${local.template_path}/install-worker-userdata",
    {
      kubernetes_release        = var.kubernetes_release
      boot_token                = var.boot_token
      fqdn                      = var.apiserver_fqdn
      service_port              = var.apiserver_service_port
      certificate_authority_pem = var.ca_cert_pem
    }
  )
  zone = "${var.region}-${var.worker_zone == "" ? (count.index % 2 == 0 ? "a" : "b") : var.worker_zone}"

  server_groups = [var.cluster_server_group, brightbox_server_group.k8s_worker_group.id]

  lifecycle {
    ignore_changes = [
      image,
      type,
      server_groups,
    ]
    create_before_destroy = true
  }

  provisioner "remote-exec" {
    when = destroy

    connection {
      type = "ssh"
      user = var.bastion_user
      host = var.bastion
    }

    inline = [
      "kubectl drain --ignore-daemonsets --timeout=${var.worker_drain_timeout} ${self.id}",
    ]
  }

}

resource "null_resource" "k8s_worker_upgrade" {

  depends_on = [
    var.apiserver_ready,
  ]

  count = length(brightbox_server.k8s_worker)

  triggers = {
    worker_id      = brightbox_server.k8s_worker[count.index].id
    k8s_release    = var.kubernetes_release
    boot_token     = var.boot_token
    fqdn           = var.apiserver_fqdn
    service_port   = var.apiserver_service_port
    install_script = file("${local.template_path}/upgrade-worker")
    cert_change    = var.ca_cert_pem
  }

  connection {
    user         = brightbox_server.k8s_worker[count.index].username
    host         = brightbox_server.k8s_worker[count.index].hostname
    bastion_host = var.bastion
    bastion_user = var.bastion_user
  }

  provisioner "remote-exec" {
    inline = [
      local.upgrade_script
    ]
  }
}

data "brightbox_image" "k8s_worker" {
  name        = var.image_desc
  arch        = "x86_64"
  official    = true
  most_recent = true
}

