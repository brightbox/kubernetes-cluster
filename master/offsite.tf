resource "digitalocean_droplet" "offsite" {

  count = var.offsite_count

  name      = "k8s-master-offsite.${local.cluster_fqdn}"
  region    = var.offsite_region
  size      = var.offsite_type
  image     = var.offsite_image
  ssh_keys  = [data.digitalocean_ssh_key.offsite[count.index].id]
  user_data = local.cloud_config
  ipv6      = true

  lifecycle {
    create_before_destroy = true
  }
}

resource "brightbox_firewall_rule" "offsite_etcd_ipv6" {
  count            = var.offsite_count
  destination_port = "2379,2380"
  protocol         = "tcp"
  source           = digitalocean_droplet.offsite[count.index].ipv6_address
  description      = "Offsite Etcd peer access"
  firewall_policy  = var.cluster_firewall_policy
}

data "digitalocean_ssh_key" "offsite" {

  count = var.offsite_count

  name = var.offsite_ssh_key
}

