locals {
  external_ip = brightbox_server.k8s_master[0].ipv4_address_private
  fqdn        = brightbox_server.k8s_master[0].fqdn
  ipv6_fqdn   = brightbox_server.k8s_master[0].ipv6_hostname
  public_ip   = brightbox_cloudip.k8s_master.public_ip
  public_rdns = brightbox_cloudip.k8s_master.reverse_dns
  public_fqdn = brightbox_cloudip.k8s_master.fqdn
}

resource "brightbox_cloudip" "k8s_master" {
  target = brightbox_server.k8s_master[0].interface
  name   = "k8s-master.${var.cluster_name}"

  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${local.public_fqdn}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${local.public_ip}"
  }
}

resource "random_id" "master_certificate_key" {
  byte_length = 32
}

resource "brightbox_server" "k8s_master" {
  count      = var.master_count
  depends_on = [brightbox_firewall_policy.k8s]

  name      = "k8s-master-${count.index}.${local.cluster_fqdn}"
  image     = data.brightbox_image.k8s_master.id
  type      = var.master_type
  user_data = local.master_cloud_config
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

}

resource "null_resource" "k8s_master" {
  triggers = {
    master_id = brightbox_server.k8s_master[0].id
  }

  connection {
    user = brightbox_server.k8s_master[0].username
    host = local.public_fqdn
  }

  provisioner "file" {
    content     = tls_self_signed_cert.k8s_ca.cert_pem
    destination = "ca.crt"
  }

  provisioner "file" {
    content     = tls_private_key.k8s_ca.private_key_pem
    destination = "ca.key"
  }

  # Generic provisioners
  provisioner "remote-exec" {
    inline = [
      local.install_provisioner_script
    ]
  }

  provisioner "remote-exec" {
    when = destroy

    # The sleep 10 is a hack to workaround the lack of wait on the delete
    # command
    inline = [
      "kubectl get services -o=jsonpath='{range .items[?(.spec.type==\"LoadBalancer\")]}{\"service/\"}{.metadata.name}{\" \"}{end}' | xargs -r kubectl delete",
      "sleep 10",
    ]
  }
}

resource "null_resource" "k8s_master_mirrors" {

  count = max(0, length(brightbox_server.k8s_master) - 1)

  triggers = {
    mirror_id = brightbox_server.k8s_master[count.index + 1].id
  }

  connection {
    host         = brightbox_server.k8s_master[count.index + 1].hostname
    user         = brightbox_server.k8s_master[count.index + 1].username
    type         = "ssh"
    bastion_host = local.public_fqdn
  }

  provisioner "file" {
    content     = tls_self_signed_cert.k8s_ca.cert_pem
    destination = "ca.crt"
  }

  # Generic provisioner
  provisioner "remote-exec" {
    inline = [
      local.install_provisioner_script,
    ]
  }

}

resource "null_resource" "k8s_master_mirrors_configure" {
  depends_on = [
    null_resource.k8s_master_configure,
    null_resource.k8s_token_manager,
    null_resource.k8s_master_mirrors,
  ]

  count = max(0, length(brightbox_server.k8s_master) - 1)

  triggers = {
    cert_key       = random_id.master_certificate_key.hex
    mirror_id      = brightbox_server.k8s_master[count.index + 1].id
    k8s_release    = var.kubernetes_release
    master_script  = local.master_mirror_provisioner_script
    kubeadm_script = local.kubeadm_config_script
  }

  connection {
    host         = brightbox_server.k8s_master[count.index + 1].hostname
    user         = brightbox_server.k8s_master[count.index + 1].username
    type         = "ssh"
    bastion_host = local.public_fqdn
  }

  provisioner "remote-exec" {
    inline = [
      local.kubeadm_config_script,
      local.master_mirror_provisioner_script,
    ]
  }

}

resource "null_resource" "k8s_master_configure" {
  depends_on = [null_resource.k8s_master]

  triggers = {
    cert_key       = random_id.master_certificate_key.hex
    master_id      = brightbox_server.k8s_master[0].id
    k8s_release    = var.kubernetes_release
    master_script  = local.master_provisioner_script
    kubeadm_script = local.kubeadm_config_script
  }

  connection {
    user = brightbox_server.k8s_master[0].username
    host = local.public_fqdn
  }

  provisioner "remote-exec" {
    inline = [
      local.kubeadm_config_script,
      local.master_provisioner_script,
    ]
  }

}

resource "null_resource" "k8s_storage_configure" {
  depends_on = [null_resource.k8s_master_configure]

  triggers = {
    master_id      = brightbox_server.k8s_master[0].id
    reclaim_policy = var.reclaim_volumes
    master_script  = local.storage_class_provisioner_script
  }

  connection {
    user = brightbox_server.k8s_master[0].username
    host = local.public_fqdn
  }

  provisioner "remote-exec" {
    inline = [local.storage_class_provisioner_script]
  }
}

resource "null_resource" "k8s_token_manager" {
  depends_on = [null_resource.k8s_master_configure]

  triggers = {
    boot_token   = local.boot_token
    cert_key     = random_id.master_certificate_key.hex
    worker_count = var.worker_count
    master_count = var.master_count
  }

  connection {
    user = brightbox_server.k8s_master[0].username
    host = local.public_fqdn
  }

  provisioner "remote-exec" {
    inline = [
      "kubeadm token delete ${local.boot_token}",
      "kubeadm token create ${local.boot_token}",
      "[ '${var.kubernetes_release}' \\< '1.15' ] || sudo kubeadm init phase upload-certs --upload-certs --config $${HOME}/install/kubeadm.conf"
    ]
  }
}

data "brightbox_image" "k8s_master" {
  name        = var.image_desc
  arch        = "x86_64"
  official    = true
  most_recent = true
}
