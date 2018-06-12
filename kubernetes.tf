provider "brightbox" {
  version  = "~> 1.0"
  apiurl   = "https://api.${var.region}.brightbox.com"
  username = "${var.username}"
  password = "${var.password}"
  account  = "${var.account}"
}

resource "brightbox_server" "k8s-worker" {
  count      = "${var.worker_count}"
  depends_on = ["brightbox_firewall_policy.k8s"]

  name      = "k8s-worker-${count.index}"
  image     = "${data.brightbox_image.k8s_worker.id}"
  type      = "${var.worker_type}"
  user_data = "${data.template_file.worker-cloud-config.rendered}"

  server_groups = ["${brightbox_server_group.k8s.id}"]

  lifecycle {
    create_before_destroy = true
  }

  connection {
    bastion_host = "${var.bastion}"
  }

  provisioner "file" {
    source      = "${path.root}/checksums.txt"
    destination = "checksums.txt"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.worker-provisioner-script.rendered}"
  }
    
}

data "brightbox_image" "k8s_worker" {
  name        = "${var.image_desc}"
  arch        = "x86_64"
  official    = true
  most_recent = true
}

data "template_file" "worker-cloud-config" {
  template = "${file("${path.root}/templates/worker-cloud-config.yml")}"
}

data "template_file" "worker-provisioner-script" {
  template = "${file("${path.root}/templates/install-kube")}"

  vars {
    k8s_release                        = "${var.k8s_release}"
    critools_release                   = "${var.critools_release}"
    cni_plugins_release                = "${var.cni_plugins_release}"
    containerd_release                 = "${var.containerd_release}"
    runc_release                       = "${var.runc_release}"
    brightbox_cloud_controller_release = "${var.brightbox_cloud_controller_release}"
  }
}

data "template_file" "etcd-cloud-config" {
  template = "${file("${path.root}/templates/master-cloud-config.yml")}"

  vars {
    discovery_url = "${file("${path.root}/generated/discovery${null_resource.etcd_discovery_url.id}")}"
  }
}

resource "null_resource" "etcd_discovery_url" {
  provisioner "local-exec" {
    command = "[ -d ${path.root}/generated ] || mkdir -p ${path.root}/generated && curl -sSL --retry 3 https://discovery.etcd.io/new?size=${var.worker_count} > ${path.root}/generated/discovery${self.id}"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "rm -f ${path.root}/generated/discovery${self.id}"
  }
}
