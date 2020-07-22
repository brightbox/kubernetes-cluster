locals {
  template_path   = "${path.module}/templates"
  etcd_configured = null_resource.etcd_reconfigure.id
  cluster_members = [for s in var.servers : "${s.id}=https://[${s.address}]:2380"]
  all_endpoints = join(",",[for s in var.servers: "[${s.address}]:2379"])
}

resource "null_resource" "etcd_install" {
  depends_on = [
    var.deps
  ]
  count = length(var.servers)

  triggers = {
    install_etcd    = file("${local.template_path}/install-etcd")
    install_certs   = file("${local.template_path}/install-certs")
    reconfig_etcd   = file("${local.template_path}/reconfig_etcd")
    cluster_members = join(",", local.cluster_members)
    cluster_state = tostring(var.new_cluster)
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
    content     = tls_self_signed_cert.etcd_ca.cert_pem
    destination = "/tmp/etcd-certs/etcd/ca.crt"
  }

  provisioner "file" {
    content     = tls_private_key.etcd_ca.private_key_pem
    destination = "/tmp/etcd-certs/etcd/ca.key"
  }

  provisioner "file" {
    source = "${local.template_path}/reconfig_etcd"
    destination = "/tmp/reconfig_etcd"
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
          cluster_state   = var.new_cluster ? "new" : "existing"
          peer_urls       = "https://[${var.servers[count.index].address}]:2380"
          client_urls     = "https://[${var.servers[count.index].address}]:2379"
          all_endpoints = local.all_endpoints
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

resource "tls_private_key" "etcd_ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "etcd_ca" {
  key_algorithm   = tls_private_key.etcd_ca.algorithm
  private_key_pem = tls_private_key.etcd_ca.private_key_pem

  subject {
    common_name         = "etcd-ca"
    organizational_unit = var.organizational_unit
  }

  validity_period_hours = var.validity_period
  early_renewal_hours   = var.renew_period

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}
