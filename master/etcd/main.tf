locals {
  template_path   = "${path.module}/templates"
  etcd_configured = null_resource.etcd_reconfigure.id
  cluster_members = [for s in var.servers : "${s.id}=https://[${s.address}]:2380"]
}

resource "null_resource" "etcd_install" {
  count = length(var.servers)

  triggers = {
    install_etcd    = file("${local.template_path}/install-etcd")
    install_certs   = file("${local.template_path}/install-certs")
    cluster_members = join(",", local.cluster_members)
  }

  connection {
    host         = var.servers[count.index].address
    user         = var.servers[count.index].username
    type         = "ssh"
    bastion_host = var.bastion
    bastion_user = var.bastion_user
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/etcd-certs/etcd"
    ]
  }

  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "/tmp/etcd-certs/etcd/ca.crt"
  }

  provisioner "file" {
    content     = var.ca_private_key_pem
    destination = "/tmp/etcd-certs/etcd/ca.key"
  }

  provisioner "remote-exec" {
    inline = [
      templatefile(
        "${local.template_path}/install-certs",
        {
          id      = var.servers[count.index].id
          address = var.servers[count.index].address
        }
      ),
      templatefile(
        "${local.template_path}/install-etcd",
        {
          cluster_members = join(",", local.cluster_members)
          bootstrap_node  = count.index == 0 ? local.cluster_members[count.index] : ""
          secondary_node  = count.index == 1 ? join(",", slice(local.cluster_members, 0, 2)) : ""
          peer_urls       = "https://[${var.servers[count.index].address}]:2380"
          client_urls     = "https://[${var.servers[count.index].address}]:2379"
          id              = var.servers[count.index].id
        }
      )
    ]
  }
}

resource "null_resource" "etcd_reconfigure" {

  depends_on = [
    null_resource.etcd_install
  ]

  triggers = {
    ectd_reconfig = join(",", null_resource.etcd_install.*.id)
  }


}
