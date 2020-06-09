resource "digitalocean_droplet" "offsite" {
  depends_on = [var.cluster_ready]

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

data "digitalocean_ssh_key" "offsite" {

  count = var.offsite_count

  name = var.offsite_ssh_key
}

