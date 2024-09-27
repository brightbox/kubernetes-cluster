locals {
  template_path = "${path.module}/templates"
  upgrade_script = templatefile(
    "${local.template_path}/upgrade-worker",
    {
      kubernetes_release = var.kubernetes_release
      critools_release   = var.critools_release
    }
  )
  user_data = templatefile(
    "${local.template_path}/install-worker-userdata",
    {
      kubernetes_release        = var.kubernetes_release
      critools_release          = var.critools_release
      boot_token                = var.boot_token
      fqdn                      = var.apiserver_fqdn
      service_port              = var.apiserver_service_port
      certificate_authority_pem = var.ca_cert_pem
      storage_system            = var.storage_system
    }
  )
}

resource "brightbox_server_group" "k8s_worker" {
  name        = "${var.worker_name}.${var.internal_cluster_fqdn}"
  description = "${var.worker_count}:${var.worker_max}"
}

resource "brightbox_config_map" "k8s_worker" {
  name = "${var.worker_name}.${var.internal_cluster_fqdn}"
  data = {
    min               = var.worker_count
    max               = var.worker_max
    image             = var.image_desc
    type              = var.worker_type
    region            = var.region
    zone              = var.worker_zone
    user_data         = data.cloudinit_config.worker_userdata.rendered
    server_group      = brightbox_server_group.k8s_worker.id
    default_group     = var.cluster_server_group
    additional_groups = join(",", var.additional_server_groups)
  }
}

data "cloudinit_config" "worker_userdata" {
  gzip          = false
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = <<EOT
#cloud-config
%{if var.root_size != 0~}
bootcmd:
  - [cloud-init-per, once, addpartition, sgdisk, /dev/vda, "-e", "-n=0:${var.root_size}G:0"]
  - [cloud-init-per, once, probepartitions, partprobe]
%{~endif}
package_update: false
EOT
  }

  part {
    content_type = "text/x-shellscript"
    content      = local.user_data
  }
}

resource "brightbox_server" "k8s_worker" {
  depends_on = [
    var.cluster_ready,
    var.apiserver_ready,
  ]
  count = var.worker_count

  name             = "${var.worker_name}-${count.index}.${var.internal_cluster_fqdn}"
  image            = data.brightbox_image.k8s_worker.id
  type             = brightbox_config_map.k8s_worker.data["type"]
  user_data_base64 = brightbox_config_map.k8s_worker.data["user_data"]
  zone             = brightbox_config_map.k8s_worker.data["zone"] == "" ? "${brightbox_config_map.k8s_worker.data["region"]}-${(count.index % 2 == 0 ? "a" : "b")}" : brightbox_config_map.k8s_worker.data["zone"]

  server_groups = concat([brightbox_config_map.k8s_worker.data["default_group"], brightbox_config_map.k8s_worker.data["server_group"]], var.additional_server_groups)

  lifecycle {
    ignore_changes = [
      image,
      type,
      zone,
      server_groups,
    ]
    create_before_destroy = true
  }

}

resource "null_resource" "k8s_worker_upgrade" {

  depends_on = [
    var.apiserver_ready,
  ]

  count = var.worker_count

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
