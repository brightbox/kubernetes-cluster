locals {
  template_path = "${path.module}/templates"
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

resource "brightbox_server" "k8s_worker" {
  depends_on = [
    var.cluster_ready
  ]
  count = var.worker_count

  name      = "${var.worker_name}-${count.index}.${var.internal_cluster_fqdn}"
  image     = data.brightbox_image.k8s_worker.id
  type      = var.worker_type
  user_data = var.cloud_config
  zone      = "${var.region}-${var.worker_zone == "" ? (count.index % 2 == 0 ? "a" : "b") : var.worker_zone}"

  server_groups = [var.cluster_server_group]

  lifecycle {
    ignore_changes = [
      image,
      type,
      server_groups,
    ]
    create_before_destroy = true
  }

}

resource "null_resource" "k8s_worker" {
  depends_on = [
    var.apiserver_ready
  ]
  count = var.worker_count
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

  # Just the public key, so it can be hashed on the server
  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "ca.crt"
  }

  provisioner "remote-exec" {
    inline = [var.install_script]
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

resource "null_resource" "k8s_worker_configure" {

  depends_on = [
    null_resource.k8s_worker_token_manager,
    null_resource.k8s_worker,
  ]

  count = var.worker_count

  triggers = {
    worker_id      = brightbox_server.k8s_worker[count.index].id
    k8s_release    = var.kubernetes_release
    prefix         = random_string.token_prefix[count.index].result
    suffix         = random_string.token_suffix[count.index].result
    fqdn           = var.apiserver_fqdn
    service_port   = var.apiserver_service_port
    kubeadm_script = var.kubeadm_config_script
    install_script = file("${local.template_path}/install-worker")
  }

  connection {
    user         = brightbox_server.k8s_worker[count.index].username
    host         = brightbox_server.k8s_worker[count.index].hostname
    bastion_host = var.bastion
    bastion_user = var.bastion_user
  }

  provisioner "remote-exec" {
    inline = [
      var.kubeadm_config_script,
      templatefile(
        "${local.template_path}/install-worker",
        {
          kubernetes_release = var.kubernetes_release
          boot_token         = "${random_string.token_prefix[count.index].result}.${random_string.token_suffix[count.index].result}",
          fqdn               = var.apiserver_fqdn
          service_port       = var.apiserver_service_port
        }
      ),
    ]
  }
}

data "brightbox_image" "k8s_worker" {
  name        = var.image_desc
  arch        = "x86_64"
  official    = true
  most_recent = true
}
