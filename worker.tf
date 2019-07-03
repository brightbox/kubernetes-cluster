resource "brightbox_server" "k8s_worker" {
  count = var.worker_count
  depends_on = [
    brightbox_server.k8s_master,
    brightbox_firewall_policy.k8s,
    brightbox_cloudip.k8s_master,
    brightbox_firewall_rule.k8s_ssh,
    brightbox_firewall_rule.k8s_icmp,
    brightbox_firewall_rule.k8s_outbound,
    brightbox_firewall_rule.k8s_intra_group,
    brightbox_firewall_rule.k8s_cluster
  ]

  name      = "k8s-worker-${count.index}.${local.cluster_fqdn}"
  image     = data.brightbox_image.k8s_worker.id
  type      = var.worker_type
  user_data = local.worker_cloud_config
  zone      = "${var.region}-${count.index % 2 == 0 ? "a" : "b"}"

  server_groups = [brightbox_server_group.k8s.id]

  lifecycle {
    ignore_changes = [
      image,
      type,
      server_groups,
    ]
    create_before_destroy = true
  }

  connection {
    host         = self.hostname
    user         = self.username
    type         = "ssh"
    bastion_host = local.public_fqdn
  }

  # Just the public key, so it can be hashed on the server
  provisioner "file" {
    content     = tls_self_signed_cert.k8s_ca.cert_pem
    destination = "ca.crt"
  }

  provisioner "remote-exec" {
    inline = [local.install_provisioner_script]
  }

  provisioner "remote-exec" {
    when = destroy

    connection {
      type = "ssh"
      user = brightbox_server.k8s_master[0].username
      host = local.public_fqdn
    }

    inline = [
      "kubectl drain --ignore-daemonsets --timeout=${var.worker_drain_timeout} ${self.id}",
      "kubectl delete node ${self.id}",
    ]
  }
}

resource "null_resource" "k8s_worker_configure" {
  depends_on = [
    null_resource.k8s_master_configure,
    null_resource.k8s_token_manager,
  ]

  count = length(brightbox_server.k8s_worker)

  triggers = {
    worker_id      = brightbox_server.k8s_worker[count.index].id
    k8s_release    = var.kubernetes_release
    vol_count      = var.worker_vol_count
    worker_script  = local.worker_provisioner_script
    kubeadm_script = local.kubeadm_config_script
  }

  connection {
    user         = brightbox_server.k8s_worker[count.index].username
    host         = brightbox_server.k8s_worker[count.index].hostname
    bastion_host = local.public_fqdn
  }

  provisioner "remote-exec" {
    inline = [
      local.kubeadm_config_script,
      local.worker_provisioner_script
    ]
  }
}

data "brightbox_image" "k8s_worker" {
  name        = var.image_desc
  arch        = "x86_64"
  official    = true
  most_recent = true
}

