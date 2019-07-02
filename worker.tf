resource "brightbox_server" "k8s_worker" {
  count = var.worker_count
  depends_on = [
    brightbox_firewall_policy.k8s,
    brightbox_cloudip.k8s_master,
    brightbox_firewall_rule.k8s_ssh,
    brightbox_firewall_rule.k8s_icmp,
    brightbox_firewall_rule.k8s_outbound,
    brightbox_firewall_rule.k8s_intra_group,
  ]

  name      = "k8s-worker-${count.index}.${local.cluster_fqdn}"
  image     = data.brightbox_image.k8s_worker.id
  type      = var.worker_type
  user_data = data.template_file.worker-cloud-config.rendered
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
    user = self.username
    type         = "ssh"
    bastion_host = brightbox_cloudip.k8s_master.fqdn
  }

  # Just the public key, so it can be hashed on the server
  # Just the public key, so it can be hashed on the server
  provisioner "file" {
    content     = tls_self_signed_cert.k8s_ca.cert_pem
    destination = "ca.crt"
  }

  provisioner "remote-exec" {
    inline = data.template_file.install-provisioner-script.rendered
  }

  provisioner "remote-exec" {
    when = destroy

    connection {
      type = "ssh"
      user = brightbox_server.k8s_master[0].username
      host = brightbox_cloudip.k8s_master.fqdn
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
    worker_script  = data.template_file.worker-provisioner-script.rendered
    kubeadm_script = data.template_file.kubeadm-config-script.rendered
  }

  connection {
    user         = brightbox_server.k8s_worker[count.index].username
    host         = brightbox_server.k8s_worker[count.index].hostname
    bastion_host = brightbox_cloudip.k8s_master.fqdn
  }

  provisioner "remote-exec" {
    inline = data.template_file.kubeadm-config-script.rendered
  }

  provisioner "remote-exec" {
    inline = data.template_file.worker-provisioner-script.rendered
  }
}

data "brightbox_image" "k8s_worker" {
  name        = var.image_desc
  arch        = "x86_64"
  official    = true
  most_recent = true
}

data "template_file" "worker-cloud-config" {
  template = file("${local.template_path}/cloud-config.yml")
}

data "template_file" "worker-provisioner-script" {
  template = file("${local.template_path}/install-worker")

  vars = {
    kubernetes_release = var.kubernetes_release
    worker_vol_count   = var.worker_vol_count
    boot_token         = local.boot_token
    fqdn               = local.fqdn
  }
}

