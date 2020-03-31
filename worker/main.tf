locals {
  user_data_script = <<EOT
#cloud-config
%{if var.root_size != 0~}
bootcmd:
  - [cloud-init-per, once, addpartition, sgdisk, /dev/vda, "-e", "-n=0:${var.root_size}G:0"]
%{~endif}
EOT
}

resource "brightbox_server_group" "k8s_worker_group" {
  name        = "${var.worker_name}.${var.internal_cluster_fqdn}"
  description = "${var.worker_count}:${var.worker_max}"
}

resource "brightbox_server" "k8s_worker" {
  depends_on = [
    var.cluster_ready
  ]
  count = var.worker_count

  name      = "${var.worker_name}-${count.index}.${var.internal_cluster_fqdn}"
  image     = data.brightbox_image.k8s_worker.id
  type      = var.worker_type
  zone      = "${var.region}-${var.worker_zone == "" ? (count.index % 2 == 0 ? "a" : "b") : var.worker_zone}"
  user_data = local.user_data_script

  server_groups = [var.cluster_server_group, brightbox_server_group.k8s_worker_group.id]

  lifecycle {
    ignore_changes = [
      image,
      type,
      server_groups,
    ]
    create_before_destroy = true
  }

}

data "brightbox_image" "k8s_worker" {
  name        = var.image_desc
  arch        = "x86_64"
  official    = true
  most_recent = true
}

