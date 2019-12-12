locals {
  template_path = "${path.module}/templates"
  upgrade_script = templatefile(
    "${local.template_path}/upgrade-worker",
    { kubernetes_release = var.kubernetes_release }
  )
}

resource "random_string" "token_suffix" {
  count   = var.worker_count
  length  = 16
  special = false
  upper   = false
}

resource "random_string" "token_prefix" {
  count   = var.worker_count
  length  = 6
  special = false
  upper   = false
}

resource "brightbox_server_group" "k8s_worker_group" {
  name        = "${var.worker_name}.${var.internal_cluster_fqdn}"
  description = "${var.worker_min}:${var.worker_max}"
}

resource "null_resource" "k8s_worker_token_manager" {
  depends_on = [var.apiserver_ready]
  count      = var.worker_count

  connection {
    user = var.bastion_user
    host = var.bastion
  }

  provisioner "remote-exec" {
    inline = [
      "kubeadm token create ${random_string.token_prefix[count.index].result}.${random_string.token_suffix[count.index].result}",
    ]
  }
}

resource "brightbox_server" "k8s_worker" {
  depends_on = [
    var.cluster_ready,
    null_resource.k8s_worker_token_manager,
  ]
  count = var.worker_count

  name  = "${var.worker_name}-${count.index}.${var.internal_cluster_fqdn}"
  image = data.brightbox_image.k8s_worker.id
  type  = var.worker_type
  user_data = templatefile(
    "${local.template_path}/install-worker-userdata",
    {
      kubernetes_release        = var.kubernetes_release
      boot_token                = "${random_string.token_prefix[count.index].result}.${random_string.token_suffix[count.index].result}",
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
    ]
    create_before_destroy = true
  }

}

resource "null_resource" "k8s_worker_drain" {
  depends_on = [
    var.apiserver_ready
  ]
  count = length(brightbox_server.k8s_worker)
  triggers = {
    worker_id = brightbox_server.k8s_worker[count.index].id
  }

  connection {
    host         = brightbox_server.k8s_worker[count.index].hostname
    user         = brightbox_server.k8s_worker[count.index].username
    type         = "ssh"
    bastion_host = var.bastion
    bastion_user = var.bastion_user
  }

  lifecycle {
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
      "kubectl drain --ignore-daemonsets --timeout=${var.worker_drain_timeout} ${brightbox_server.k8s_worker[count.index].id}",
      "kubectl delete node ${brightbox_server.k8s_worker[count.index].id} || true",
    ]
  }
}


resource "null_resource" "k8s_worker_upgrade" {

  depends_on = [
    null_resource.k8s_worker_token_manager,
    var.apiserver_ready,
  ]

  count = length(brightbox_server.k8s_worker)

  triggers = {
    worker_id      = brightbox_server.k8s_worker[count.index].id
    k8s_release    = var.kubernetes_release
    prefix         = random_string.token_prefix[count.index].result
    suffix         = random_string.token_suffix[count.index].result
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

