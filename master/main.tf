locals {
  local_host    = "127.0.0.1"
  template_path = "${path.module}/templates"
  cluster_fqdn  = "${var.cluster_name}.${var.cluster_domainname}"
  boot_token    = "${random_string.token_prefix.result}.${random_string.token_suffix.result}"
  public_ip     = brightbox_cloudip.k8s_master.public_ip
  public_rdns   = brightbox_cloudip.k8s_master.reverse_dns
  public_fqdn   = brightbox_cloudip.k8s_master.fqdn
  lb_count      = var.master_count > 1 ? 1 : 0
  bastion       = local.lb_count == 1 ? brightbox_cloudip.bastion[0].fqdn : local.public_fqdn
  bastion_ip    = local.lb_count == 1 ? brightbox_cloudip.bastion[0].public_ip : local.public_ip
  bastion_user  = brightbox_server.k8s_master[0].username
  api_target    = local.lb_count == 1 ? brightbox_load_balancer.k8s_master[0].id : brightbox_server.k8s_master[0].interface
  install_script = templatefile(
    "${local.template_path}/install-kube",
    { kubernetes_release = var.kubernetes_release }
  )
  cloud_config = file("${local.template_path}/cloud-config.yml")
}

resource "brightbox_cloudip" "k8s_master" {
  # The firewall rules have to be there before the bastion will work. 
  # This is used as the bastion ip if there is only one master.
  depends_on = [
    var.cluster_ready,
    brightbox_load_balancer.k8s_master,
    brightbox_firewall_rule.k8s_lb,
  ]
  name   = "k8s-master.${var.cluster_name}"
  target = local.api_target

  provisioner "local-exec" {
    when    = destroy
    command = "ssh-keygen -R ${self.fqdn}; ssh-keygen -R ${self.public_ip}"
  }
}

resource "brightbox_load_balancer" "k8s_master" {
  count = local.lb_count
  name  = "k8s-master.${var.cluster_name}"
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
  name   = "bastion.${var.cluster_name}"
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

  name      = "k8s-master-${count.index}.${local.cluster_fqdn}"
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

resource "null_resource" "k8s_master" {
  triggers = {
    master_id   = brightbox_server.k8s_master[0].id
    cert_change = var.ca_cert_pem
  }

  connection {
    user = local.bastion_user
    host = local.bastion
  }

  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "ca.crt"
  }

  provisioner "file" {
    content     = var.ca_private_key_pem
    destination = "ca.key"
  }

  # Generic provisioner
  provisioner "remote-exec" {
    inline = [
      local.install_script
    ]
  }

  #  provisioner "remote-exec" {
  #  when = destroy
  #
  #  # The sleep 10 is a hack to workaround the lack of wait on the delete
  #  # command
  #  inline = [
  #    "kubectl get services -o=jsonpath='{range .items[?(.spec.type==\"LoadBalancer\")]}{\"service/\"}{.metadata.name}{\" \"}{end}' | xargs -r kubectl delete",
  #    "sleep 10",
  #  ]
  #}
}

resource "null_resource" "k8s_master_configure" {
  depends_on = [
    null_resource.k8s_master,
  ]

  triggers = {
    cert_key       = random_id.master_certificate_key.hex
    master_ids     = join(",", brightbox_server.k8s_master.*.id)
    k8s_release    = var.kubernetes_release
    cert_change    = var.ca_cert_pem
    master_script  = local.master_provisioner_script
    kubeadm_script = local.kubeadm_config_script
    cert_change    = var.ca_cert_pem
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
    null_resource.k8s_master_configure,
  ]

  count = max(0, length(brightbox_server.k8s_master) - 1)

  triggers = {
    mirror_id   = brightbox_server.k8s_master[count.index + 1].id
    cert_change = var.ca_cert_pem
  }

  connection {
    host         = brightbox_server.k8s_master[count.index + 1].hostname
    user         = brightbox_server.k8s_master[count.index + 1].username
    type         = "ssh"
    bastion_host = local.bastion
    bastion_user = local.bastion_user
  }

  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "ca.crt"
  }

  provisioner "file" {
    content     = var.ca_private_key_pem
    destination = "ca.key"
  }

  # Generic provisioner
  provisioner "remote-exec" {
    inline = [
      local.install_script
    ]
  }

}

resource "null_resource" "k8s_master_mirrors_configure" {
  depends_on = [
    null_resource.k8s_master_configure,
    null_resource.k8s_master_mirrors,
  ]

  count = max(0, length(brightbox_server.k8s_master) - 1)

  triggers = {
    cert_key       = random_id.master_certificate_key.hex
    mirror_id      = brightbox_server.k8s_master[count.index + 1].id
    k8s_release    = var.kubernetes_release
    cert_change    = var.ca_cert_pem
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
    inline = [
      "echo 'Waiting for base package installation to complete'",
      "cloud-init status --wait >/dev/null"
    ]
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
  name              = "Cloud Controller ${var.cluster_name}"
  permissions_group = "full"
}

locals {

  master_provisioner_script = templatefile("${local.template_path}/install-master", {
    kubernetes_release       = var.kubernetes_release,
    calico_release           = var.calico_release,
    cluster_name             = var.cluster_name,
    public_ip                = local.public_ip,
    public_fqdn              = local.public_fqdn,
    boot_token               = local.boot_token,
    service_cluster_ip_range = var.service_cidr,
    controller_client        = brightbox_api_client.controller_client.id,
    controller_client_secret = brightbox_api_client.controller_client.secret,
    apiurl                   = "https://api.${var.region}.brightbox.com",
    service_port             = var.apiserver_service_port,
    local_host               = local.local_host
    storage_system           = var.storage_system
    }
  )

  master_mirror_provisioner_script = templatefile("${local.template_path}/install-master-mirror", {
    kubernetes_release       = var.kubernetes_release,
    calico_release           = var.calico_release,
    cluster_name             = var.cluster_name,
    public_fqdn              = local.public_fqdn,
    service_cluster_ip_range = var.service_cidr,
    controller_client        = brightbox_api_client.controller_client.id,
    controller_client_secret = brightbox_api_client.controller_client.secret,
    apiurl                   = "https://api.${var.region}.brightbox.com",
    boot_token               = local.boot_token
    fqdn                     = local.public_fqdn
    master_certificate_key   = random_id.master_certificate_key.hex,
    service_port             = var.apiserver_service_port
    }
  )

  kubeadm_config_script = templatefile(
    "${local.template_path}/kubeadm-config",
    {
      kubernetes_release     = var.kubernetes_release,
      cluster_name           = var.cluster_name,
      cluster_domainname     = var.cluster_domainname,
      service_cidr           = var.service_cidr,
      cluster_cidr           = var.cluster_cidr,
      public_ip              = local.public_ip,
      public_rdns            = local.public_rdns,
      public_fqdn            = local.public_fqdn,
      boot_token             = local.boot_token,
      master_certificate_key = random_id.master_certificate_key.hex,
      service_port           = var.apiserver_service_port,
    }
  )

  masters_configured = concat([null_resource.k8s_master_configure.id], null_resource.k8s_master_mirrors_configure[*].id)

}

resource "random_id" "master_certificate_key" {
  byte_length = 32
}

resource "random_string" "token_suffix" {
  length  = 16
  special = false
  upper   = false
}

resource "random_string" "token_prefix" {
  length  = 6
  special = false
  upper   = false
}

