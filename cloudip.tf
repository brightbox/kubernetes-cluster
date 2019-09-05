locals {
  nodes = concat(module.k8s_worker.servers, module.k8s_storage.servers)
}

resource "brightbox_cloudip" "workers" {
  count  = var.worker_cloudip_count
  target = local.nodes[count.index].interface
  name   = "k8s-worker-${count.index}.${local.cluster_fqdn}"
}
