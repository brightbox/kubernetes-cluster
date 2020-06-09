# Computed variables
locals {
  validity_period           = 87600
  renew_period              = 730
  region_suffix             = "${var.region}.brightbox.com"
  template_path             = "${path.root}/templates"
  service_cidr              = "172.30.0.0/16"
  cluster_cidr              = "192.168.0.0/16"
  cluster_fqdn              = "${var.cluster_name}.${var.cluster_domainname}"
  service_port              = "6443"
  worker_node_ids           = module.k8s_worker.servers[*].id
  storage_node_ids          = module.k8s_storage.servers[*].id
  offsite_count             = var.master_count > 1 && var.offsite_token != "" ? 1 : 0
  worker_label_script       = <<EOT
%{if var.worker_count != 0~}
      kubectl label --overwrite ${join(" ", formatlist("node/%s", local.worker_node_ids))} 'node-role.kubernetes.io/worker=' 'node-role.kubernetes.io/storage-'
%{~endif}
EOT
  storage_label_script      = <<EOT
%{if var.storage_count != 0~}
      kubectl label --overwrite ${join(" ", formatlist("node/%s", local.storage_node_ids))} 'node-role.kubernetes.io/storage=' 'node-role.kubernetes.io/worker-'
%{~endif}
EOT
  disable_scale_down_script = <<EOT
      kubectl annotate --overwrite -l node-role.kubernetes.io/worker nodes cluster-autoscaler.kubernetes.io/scale-down-disabled=true
      kubectl annotate --overwrite -l node-role.kubernetes.io/storage nodes cluster-autoscaler.kubernetes.io/scale-down-disabled=true
EOT
}

resource "null_resource" "spread_deployments" {

  depends_on = [
    module.k8s_worker,
    module.k8s_storage,
    module.k8s_master,
  ]

  connection {
    user = module.k8s_master.bastion_user
    host = module.k8s_master.bastion
  }

  provisioner "remote-exec" {
    script = "${local.template_path}/spread-deployments"
  }

}

resource "null_resource" "label_nodes" {

  depends_on = [
    module.k8s_worker,
    module.k8s_storage,
    module.k8s_master,
  ]

  triggers = {
    worker_script  = local.worker_label_script
    storage_script = local.storage_label_script
    disable_script = local.disable_scale_down_script
  }

  connection {
    user = module.k8s_master.bastion_user
    host = module.k8s_master.bastion
  }

  provisioner "remote-exec" {
    inline = [
      local.worker_label_script,
      local.storage_label_script,
      local.disable_scale_down_script,
    ]
  }

}

resource "tls_private_key" "k8s_ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "k8s_ca" {
  key_algorithm   = tls_private_key.k8s_ca.algorithm
  private_key_pem = tls_private_key.k8s_ca.private_key_pem

  subject {
    common_name         = "apiserver"
    organizational_unit = local.cluster_fqdn
  }

  validity_period_hours = local.validity_period
  early_renewal_hours   = local.renew_period

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}
