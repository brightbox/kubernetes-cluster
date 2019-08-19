module "k8s_cluster" {
  source = "./cluster"
  #Dependencies

  #Variables
  cluster_fqdn      = local.cluster_fqdn
  management_source = var.management_source
  service_port      = local.service_port

  #Injections
}
