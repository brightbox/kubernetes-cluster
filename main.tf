# Computed variables
locals {
  validity_period   = 2562047
  region_suffix     = "${var.region}.brightbox.com"
  template_path     = "${path.root}/templates"
  service_cidr      = var.dual_stack ? "172.30.0.0/16,fd00:ac1e::/112" : "172.30.0.0/16"
  cluster_cidr      = var.dual_stack ? "192.168.0.0/16,fd00:c0a8::/48" : "192.168.0.0/16"
  cluster_fqdn      = "${var.cluster_name}.${var.cluster_domainname}"
  service_port      = "6443"
  k8s_minor_release = join(".", slice(split(".", var.kubernetes_release), 0, 2))
  critools_release  = coalesce(var.critools_release, tonumber(split(".", var.kubernetes_release)[1]) < 24 ? "1.25" : local.k8s_minor_release)
  # Calico release used with each Kubernetes minor version, taken from the
  # last default set while that minor was the default. The install script
  # needs 3.24 or later (manifest URL), so 1.22-1.24 use 3.24.6.
  calico_releases = {
    "1.22" = "3.24.6"
    "1.23" = "3.24.6"
    "1.24" = "3.24.6"
    "1.25" = "3.25.0"
    "1.26" = "3.25.1"
    "1.27" = "3.26.1"
    "1.28" = "3.27.0"
    "1.29" = "3.27.2"
    "1.30" = "3.28.0"
    "1.31" = "3.29.1"
    "1.32" = "3.29.1"
    "1.33" = "3.31.4"
    "1.34" = "3.31.4"
    "1.35" = "3.31.4"
  }
  calico_release = coalesce(var.calico_release, lookup(local.calico_releases, local.k8s_minor_release, ""))
  # Cluster autoscaler release used with each Kubernetes minor version, taken
  # from the last default set while that minor was the default. 1.33 and 1.34
  # were never the default, so they use the latest published tag.
  autoscaler_releases = {
    "1.22" = "1.22.2"
    "1.23" = "1.23.0"
    "1.24" = "1.24.0"
    "1.25" = "1.25.0"
    "1.26" = "1.26.2"
    "1.27" = "1.27.1"
    "1.28" = "1.28.2"
    "1.29" = "1.29.0"
    "1.30" = "1.30.2"
    "1.31" = "1.31.1"
    "1.32" = "1.32.0"
    "1.33" = "1.33.4"
    "1.34" = "1.34.3"
    "1.35" = "1.35.0"
  }
  autoscaler_release        = coalesce(var.autoscaler_release, lookup(local.autoscaler_releases, local.k8s_minor_release, local.k8s_minor_release))
  worker_node_ids           = module.k8s_worker.servers[*].id
  storage_node_ids          = module.k8s_storage.servers[*].id
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
  private_key_pem = tls_private_key.k8s_ca.private_key_pem

  subject {
    common_name         = "apiserver"
    organizational_unit = local.cluster_fqdn
  }

  validity_period_hours = local.validity_period

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}
