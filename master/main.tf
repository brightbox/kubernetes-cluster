locals {
  local_host    = "::"
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

locals {
  hostnames         = concat(brightbox_server.k8s_master.*.hostname, digitalocean_droplet.offsite.*.ipv4_address)
  usernames         = concat(brightbox_server.k8s_master.*.username, [for o in digitalocean_droplet.offsite : "root"])
  ipv6              = concat(brightbox_server.k8s_master.*.ipv6_address, digitalocean_droplet.offsite.*.ipv6_address)
  ipv4              = concat(brightbox_server.k8s_master.*.ipv4_address_private, digitalocean_droplet.offsite.*.ipv4_address)
  mirrors_hostnames = slice(local.hostnames, 1, length(local.hostnames))
  mirrors_usernames = slice(local.usernames, 1, length(local.usernames))
  mirrors_ipv6      = slice(local.ipv6, 1, length(local.ipv6))
  mirrors_ipv4      = slice(local.ipv4, 1, length(local.ipv4))
}

resource "null_resource" "k8s_master_configure" {

  triggers = {
    cert_key      = random_id.master_certificate_key.hex
    master_ids    = join(",", local.hostnames)
    k8s_release   = var.kubernetes_release
    cert_change   = var.ca_cert_pem
    local_script  = local.install_script
    master_script = local.master_provisioner_script
    cert_change   = var.ca_cert_pem
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

  provisioner "remote-exec" {
    inline = [
      local.install_script,
      templatefile(
        "${local.template_path}/kubeadm-config",
        {
          kubernetes_release     = var.kubernetes_release,
          cluster_name           = var.cluster_name,
          cluster_domainname     = var.cluster_domainname,
          service_cidr           = var.service_cidr,
          cluster_cidr           = var.cluster_cidr,
          advertise_ip           = local.ipv4[0]
          public_ip              = local.public_ip,
          public_rdns            = local.public_rdns,
          public_fqdn            = local.public_fqdn,
          boot_token             = local.boot_token,
          cluster_domainname     = var.cluster_domainname,
          master_certificate_key = random_id.master_certificate_key.hex,
          service_port           = var.apiserver_service_port,
        }
      ),
      local.master_provisioner_script,
    ]
  }

}

resource "null_resource" "k8s_master_mirrors_configure" {
  depends_on = [
    null_resource.k8s_master_configure,
  ]

  count = length(local.mirrors_hostnames)

  triggers = {
    cert_key    = random_id.master_certificate_key.hex
    mirror_id   = local.mirrors_hostnames[count.index]
    k8s_release = var.kubernetes_release
    cert_change = var.ca_cert_pem
  }

  connection {
    host         = local.mirrors_hostnames[count.index]
    user         = local.mirrors_usernames[count.index]
    type         = "ssh"
    bastion_host = local.bastion
    bastion_user = local.bastion_user
  }

  provisioner "remote-exec" {
    inline = [
      local.install_script,
      templatefile("${local.template_path}/install-master-mirror", {
        kubernetes_release        = var.kubernetes_release,
        calico_release            = var.calico_release,
        cluster_name              = var.cluster_name,
        public_fqdn               = local.public_fqdn,
        service_cluster_ip_range  = var.service_cidr,
        controller_client         = brightbox_api_client.controller_client.id,
        controller_client_secret  = brightbox_api_client.controller_client.secret,
        apiurl                    = "https://api.${var.region}.brightbox.com",
        boot_token                = local.boot_token
        fqdn                      = local.public_fqdn
        certificate_authority_pem = var.ca_cert_pem
        master_certificate_key    = random_id.master_certificate_key.hex,
        advertise_ip              = local.mirrors_ipv4[count.index]
        service_port              = var.apiserver_service_port
        }
      ),
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

