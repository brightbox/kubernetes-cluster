locals {
  template_path   = "${path.module}/templates"
  etcd_configured = null_resource.etcd_reconfigure.id
  initial_cluster = join(",", [for s in var.servers : "${s.id}=https://[${s.address}]:2380"])
}

resource "null_resource" "etcd_install" {
  count = length(var.servers)

  triggers = {
    install_etcd  = file("${local.template_path}/install-etcd")
    install_certs = file("${local.template_path}/install-certs")
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
          initial_cluster = local.initial_cluster
          bootstrap_node  = count.index == 0 ? "${var.servers[count.index].id}=https://[${var.servers[count.index].address}]:2380" : ""
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
    etcd_change = local.initial_cluster
  }

}
