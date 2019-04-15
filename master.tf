locals {
  external_ip = "${brightbox_server.k8s_master.ipv4_address_private}"
  fqdn        = "${brightbox_server.k8s_master.fqdn}"
  ipv6_fqdn   = "${brightbox_server.k8s_master.ipv6_hostname}"
  public_ip   = "${brightbox_cloudip.k8s_master.public_ip}"
  public_rdns = "${brightbox_cloudip.k8s_master.reverse_dns}"
  public_fqdn = "${brightbox_cloudip.k8s_master.fqdn}"
}

resource "brightbox_cloudip" "k8s_master" {
  target = "${brightbox_server.k8s_master.interface}"
  name   = "k8s-master.${var.cluster_name}"

  provisioner "local-exec" {
    when    = "destroy"
    command = "ssh-keygen -R ${brightbox_cloudip.k8s_master.fqdn}"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "ssh-keygen -R ${brightbox_cloudip.k8s_master.public_ip}"
  }
}

resource "brightbox_server" "k8s_master" {
  count      = "${var.master_count}"
  depends_on = ["brightbox_firewall_policy.k8s"]

  name          = "k8s-master-${count.index}.${local.cluster_fqdn}"
  image         = "${data.brightbox_image.k8s_master.id}"
  type          = "${var.master_type}"
  user_data     = "${data.template_file.master-cloud-config.rendered}"
  server_groups = ["${brightbox_server_group.k8s.id}"]

  lifecycle {
    ignore_changes = ["image", "type"]
  }
}

resource "null_resource" "k8s_master" {
  triggers {
    master_id = "${brightbox_server.k8s_master.id}"
  }

  connection {
    user = "${brightbox_server.k8s_master.username}"
    host = "${brightbox_cloudip.k8s_master.fqdn}"
  }

  provisioner "file" {
    content     = "${tls_self_signed_cert.k8s_ca.cert_pem}"
    destination = "ca.crt"
  }

  provisioner "file" {
    content     = "${tls_private_key.k8s_ca.private_key_pem}"
    destination = "ca.key"
  }

  # Generic provisioners
  provisioner "remote-exec" {
    inline = "${data.template_file.install-provisioner-script.rendered}"
  }

  provisioner "remote-exec" {
    when = "destroy"

    # The sleep 10 is a hack to workaround the lack of wait on the delete
    # command
    inline = [
      "kubectl get services -o=jsonpath='{range .items[?(.spec.type==\"LoadBalancer\")]}{\"service/\"}{.metadata.name}{\" \"}{end}' | xargs -r kubectl delete",
      "sleep 10",
    ]
  }
}

resource "null_resource" "k8s_master_configure" {
  depends_on = ["null_resource.k8s_master"]

  triggers {
    master_id      = "${brightbox_server.k8s_master.id}"
    k8s_release    = "${var.kubernetes_release}"
    master_script  = "${data.template_file.master-provisioner-script.rendered}"
    kubeadm_script = "${data.template_file.kubeadm-config-script.rendered}"
  }

  connection {
    user = "${brightbox_server.k8s_master.username}"
    host = "${brightbox_cloudip.k8s_master.fqdn}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.kubeadm-config-script.rendered}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.master-provisioner-script.rendered}"
  }
}

resource "null_resource" "k8s_storage_configure" {
  depends_on = ["null_resource.k8s_master_configure"]

  triggers {
    master_id      = "${brightbox_server.k8s_master.id}"
    reclaim_policy = "${var.reclaim_volumes}"
    master_script  = "${data.template_file.storage-class-provisioner-script.rendered}"
  }

  connection {
    user = "${brightbox_server.k8s_master.username}"
    host = "${brightbox_cloudip.k8s_master.fqdn}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.storage-class-provisioner-script.rendered}"
  }
}

resource "null_resource" "k8s_token_manager" {
  depends_on = ["null_resource.k8s_master_configure"]

  triggers {
    boot_token   = "${local.boot_token}"
    worker_count = "${var.worker_count}"
  }

  connection {
    user = "${brightbox_server.k8s_master.username}"
    host = "${brightbox_cloudip.k8s_master.fqdn}"
  }

  provisioner "remote-exec" {
    inline = [
      "kubeadm token delete ${local.boot_token}",
      "kubeadm token create ${local.boot_token}",
    ]
  }
}

data "brightbox_image" "k8s_master" {
  name        = "${var.image_desc}"
  arch        = "x86_64"
  official    = true
  most_recent = true
}

data "template_file" "master-cloud-config" {
  template = "${file("${local.template_path}/cloud-config.yml")}"
}

data "template_file" "master-provisioner-script" {
  template = "${file("${local.template_path}/install-master")}"

  vars {
    kubernetes_release       = "${var.kubernetes_release}"
    calico_release           = "${var.calico_release}"
    cluster_name             = "${var.cluster_name}"
    external_ip              = "${local.external_ip}"
    public_fqdn              = "${local.public_fqdn}"
    service_cluster_ip_range = "${local.service_cidr}"
    controller_client        = "${brightbox_api_client.controller_client.id}"
    controller_client_secret = "${brightbox_api_client.controller_client.secret}"
    apiurl                   = "https://api.${var.region}.brightbox.com"
  }
}

data "template_file" "storage-class-provisioner-script" {
  template = "${file("${local.template_path}/define-storage-class")}"

  vars {
    storage_reclaim_policy = "${var.reclaim_volumes ? "Delete" : "Retain"}"
  }
}

data "template_file" "install-provisioner-script" {
  template = "${file("${local.template_path}/install-kube")}"

  vars {
    kubernetes_release = "${var.kubernetes_release}"
  }
}

data "template_file" "kubeadm-config-script" {
  template = "${file("${local.template_path}/kubeadm-config")}"

  vars {
    kubernetes_release = "${var.kubernetes_release}"
    cluster_name       = "${var.cluster_name}"
    cluster_domainname = "${var.cluster_domainname}"
    service_cidr       = "${local.service_cidr}"
    cluster_cidr       = "${local.cluster_cidr}"
    external_ip        = "${local.external_ip}"
    public_ip          = "${local.public_ip}"
    public_rdns        = "${local.public_rdns}"
    public_fqdn        = "${local.public_fqdn}"
    fqdn               = "${local.fqdn}"
    ipv6_fqdn          = "${local.ipv6_fqdn}"
    boot_token         = "${local.boot_token}"
    cluster_domainname = "${var.cluster_domainname}"
    hostname           = "${brightbox_server.k8s_master.hostname}"
  }
}
