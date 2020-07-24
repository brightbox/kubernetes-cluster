locals {
  servers = local.external_etcd ? [
    for host in brightbox_server.k8s_master :
    { "address" = host.ipv6_address, "username" = host.username, "id" = host.id }
  ] : []
  do_server = [
    for host in digitalocean_droplet.offsite :
    { "address" = host.ipv6_address, "username" = "root", id = split(".", host.name)[0] }
  ]
}

module "etcd" {
  source = "./etcd"

  #Variables
  bastion      = local.bastion
  bastion_user = local.bastion_user
  servers      = concat(local.servers, local.do_server)

  #Injections
  validity_period     = var.validity_period
  renew_period        = var.renew_period
  organizational_unit = local.cluster_fqdn
  deps                = brightbox_firewall_rule.offsite_etcd_ipv6
}
