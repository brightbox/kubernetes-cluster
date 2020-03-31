locals {
  local_host    = "127.0.0.1"
  template_path = "${path.module}/templates"
  public_ip     = brightbox_cloudip.k8s_master.public_ip
  public_rdns   = brightbox_cloudip.k8s_master.reverse_dns
  public_fqdn   = brightbox_cloudip.k8s_master.fqdn
  lb_count      = var.master_count > 1 ? 1 : 0
  bastion       = local.lb_count == 1 ? brightbox_cloudip.bastion[0].fqdn : local.public_fqdn
  bastion_ip    = local.lb_count == 1 ? brightbox_cloudip.bastion[0].public_ip : local.public_ip
  bastion_user  = brightbox_server.k8s_master[0].username
  api_target    = local.lb_count == 1 ? brightbox_load_balancer.k8s_master[0].id : brightbox_server.k8s_master[0].interface
  cloud_config  = file("${local.template_path}/cloud-config.yml")
}

resource "brightbox_cloudip" "k8s_master" {
  # The firewall rules have to be there before the bastion will work. 
  # This is used as the bastion ip if there is only one master.
  depends_on = [
    var.cluster_ready,
    brightbox_load_balancer.k8s_master,
    brightbox_firewall_rule.k8s_lb,
  ]
  name   = "k8s-master.${var.internal_cluster_fqdn}"
  target = local.api_target


  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${self.fqdn}; ssh-keygen -R ${self.public_ip}"
  }
}

resource "brightbox_load_balancer" "k8s_master" {
  count = local.lb_count
  name  = "k8s-master.${var.internal_cluster_fqdn}"
  listener {
    protocol = "tcp"
    in       = var.apiserver_service_port
    out      = var.apiserver_service_port
    timeout  = 86400000
  }

  healthcheck {
    type = "tcp"
    port = var.apiserver_service_port
  }

  nodes = brightbox_server.k8s_master[*].id
}

resource "brightbox_cloudip" "bastion" {
  # The firewall rules have to be there before the bastion will work
  depends_on = [
    var.cluster_ready,
    brightbox_load_balancer.k8s_master,
    brightbox_cloudip.k8s_master,
    brightbox_firewall_rule.k8s_lb,
  ]

  count  = local.lb_count
  name   = "bastion.${var.internal_cluster_fqdn}"
  target = brightbox_server.k8s_master[0].interface

  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${self.fqdn}; ssh-keygen -R ${self.public_ip}"
  }

}

resource "brightbox_firewall_rule" "k8s_lb" {
  count            = local.lb_count
  destination_port = var.apiserver_service_port
  protocol         = "tcp"
  source           = brightbox_load_balancer.k8s_master[count.index].id
  description      = "${brightbox_load_balancer.k8s_master[count.index].id} API access"
  firewall_policy  = var.cluster_firewall_policy
}

resource "brightbox_server" "k8s_master" {
  depends_on = [
    var.cluster_ready
  ]
  count = var.master_count

  name      = "k8s-master-${count.index}.${var.internal_cluster_fqdn}"
  image     = data.brightbox_image.k8s_master.id
  type      = var.master_type
  user_data = local.cloud_config
  zone      = "${var.region}-${var.master_zone == "" ? (count.index % 2 == 0 ? "a" : "b") : var.master_zone}"

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

resource "null_resource" "set_host_keys" {

  triggers = {
    bastion    = local.bastion
    bastion_ip = local.bastion_ip
  }

  provisioner "remote-exec" {
    connection {
      user = local.bastion_user
      host = local.bastion
    }
    inline = ["cloud-init status --wait"]
  }

  provisioner "local-exec" {
    command = "ssh-keyscan -H ${local.bastion_ip} >> ~/.ssh/known_hosts"
  }
  provisioner "local-exec" {
    command = "ssh-keyscan -H ${local.bastion} >> ~/.ssh/known_hosts"
  }
}


data "brightbox_image" "k8s_master" {
  name        = var.image_desc
  arch        = "x86_64"
  official    = true
  most_recent = true
}

resource "brightbox_api_client" "controller_client" {
  name              = "Cloud Controller ${var.internal_cluster_fqdn}"
  permissions_group = "full"
}

