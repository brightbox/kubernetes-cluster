locals {
  servers =  local.external_etcd ? [
    for host in brightbox_server.k8s_master :
    { "address" = host.ipv6_address, "username" = host.username }
  ] : []
  do_server = [
    for host in digitalocean_droplet.offsite :
    { "address" = host.ipv6_address, "username" = "root" }
  ]
}

module "etcd" {
  source = "./etcd"

  #Variables
  bastion      = local.bastion
  bastion_user = local.bastion_user
  servers      = concat(local.servers, local.do_server)
  
  #Injections
  ca_cert_pem             = var.etcd_ca_cert_pem
  ca_private_key_pem      = var.etcd_ca_private_key_pem

}
