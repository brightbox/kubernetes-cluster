locals {
  public_ip    = brightbox_cloudip.k8s_master.public_ip
  public_rdns  = brightbox_cloudip.k8s_master.reverse_dns
  public_fqdn  = brightbox_cloudip.k8s_master.fqdn
  lb_count     = var.master_count > 1 ? 1 : 0
  bastion      = local.lb_count == 1 ? brightbox_cloudip.bastion[0].fqdn : local.public_fqdn
  bastion_user = brightbox_server.k8s_master[0].username
  api_target   = local.lb_count == 1 ? brightbox_load_balancer.k8s_master[0].id : brightbox_server.k8s_master[0].interface
}

resource "brightbox_cloudip" "k8s_master" {
  # The firewall rules have to be there before the bastion will work. 
  # This is used as the bastion ip if there is only one master.
  depends_on = [
    module.k8s_cluster,
    brightbox_load_balancer.k8s_master,
    brightbox_firewall_rule.k8s_lb,
  ]
  name   = "k8s-master.${var.cluster_name}"
  target = local.api_target

  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${brightbox_cloudip.k8s_master.fqdn}; ssh-keygen -R ${brightbox_cloudip.k8s_master.public_ip}"
  }
}

resource "brightbox_load_balancer" "k8s_master" {
  count = local.lb_count
  name  = "k8s-master.${var.cluster_name}"
  listener {
    protocol = "tcp"
    in       = local.service_port
    out      = local.service_port
  }

  healthcheck {
    type = "tcp"
    port = local.service_port
  }

  nodes = brightbox_server.k8s_master[*].id
}

resource "brightbox_cloudip" "bastion" {
  # The firewall rules have to be there before the bastion will work
  depends_on = [
    module.k8s_cluster,
    brightbox_load_balancer.k8s_master,
    brightbox_cloudip.k8s_master,
    brightbox_firewall_rule.k8s_lb,
  ]

  count  = local.lb_count
  name   = "bastion.${var.cluster_name}"
  target = brightbox_server.k8s_master[0].interface
  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${brightbox_cloudip.bastion[count.index].fqdn}; ssh-keygen -R ${brightbox_cloudip.bastion[count.index].public_ip}"
  }

}

resource "brightbox_firewall_rule" "k8s_lb" {
  count            = local.lb_count
  destination_port = local.service_port
  protocol         = "tcp"
  source           = brightbox_load_balancer.k8s_master[count.index].id
  description      = "${brightbox_load_balancer.k8s_master[count.index].id} API access"
  firewall_policy  = module.k8s_cluster.firewall_policy_id
}

resource "random_id" "master_certificate_key" {
  byte_length = 32
}

resource "brightbox_server" "k8s_master" {
  depends_on = [
    module.k8s_cluster
  ]
  count = var.master_count

  name      = "k8s-master-${count.index}.${local.cluster_fqdn}"
  image     = data.brightbox_image.k8s_master.id
  type      = var.master_type
  user_data = local.master_cloud_config
  zone      = "${var.region}-${count.index % 2 == 0 ? "a" : "b"}"

  server_groups = [module.k8s_cluster.group_id]

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
    user = local.bastion_user
    host = local.bastion
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

resource "null_resource" "k8s_master_configure" {
  depends_on = [
    null_resource.k8s_master,
  ]

  triggers = {
    cert_key       = random_id.master_certificate_key.hex
    master_id      = brightbox_server.k8s_master[0].id
    k8s_release    = var.kubernetes_release
    master_script  = local.master_provisioner_script
    kubeadm_script = local.kubeadm_config_script
  }

  connection {
    user = local.bastion_user
    host = local.bastion
  }

  provisioner "remote-exec" {
    inline = [
      local.kubeadm_config_script,
      local.master_provisioner_script,
    ]
  }

}

resource "null_resource" "k8s_master_mirrors" {
  depends_on = [
    null_resource.k8s_token_manager,
  ]

  count = max(0, length(brightbox_server.k8s_master) - 1)

  triggers = {
    mirror_id = brightbox_server.k8s_master[count.index + 1].id
  }

  connection {
    host         = brightbox_server.k8s_master[count.index + 1].hostname
    user         = brightbox_server.k8s_master[count.index + 1].username
    type         = "ssh"
    bastion_host = local.bastion
    bastion_user = local.bastion_user
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
    bastion_host = local.bastion
    bastion_user = local.bastion_user
  }

  provisioner "remote-exec" {
    inline = [
      local.kubeadm_config_script,
      local.master_mirror_provisioner_script,
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
    user = local.bastion_user
    host = local.bastion
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
    user = local.bastion_user
    host = local.bastion
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

resource "brightbox_api_client" "controller_client" {
  name              = "Cloud Controller ${var.cluster_name}"
  permissions_group = "full"
}

