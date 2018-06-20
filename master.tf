resource "brightbox_server" "k8s_master" {
  count      = "${var.master_count}"
  depends_on = ["brightbox_firewall_policy.k8s"]

  name          = "k8s-master-${count.index}"
  image         = "${data.brightbox_image.k8s_master.id}"
  type          = "${var.master_type}"
  user_data     = "${data.template_file.master-cloud-config.rendered}"
  server_groups = ["${brightbox_server_group.k8s.id}"]

  lifecycle {
    create_before_destroy = true
  }

  connection {
    bastion_host = "${var.bastion}"
  }

  provisioner "file" {
    content     = "${element(tls_self_signed_cert.k8s_ca.*.cert_pem, 0)}"
    destination = "ca.crt"
  }

  provisioner "file" {
    content     = "${element(tls_self_signed_cert.k8s_ca.*.cert_pem, 1)}"
    destination = "etcd_ca.crt"
  }

  provisioner "file" {
    source      = "${path.root}/checksums.txt"
    destination = "checksums.txt"
  }

  provisioner "file" {
    source      = "${path.root}/templates/kubeadm.conf"
    destination = "kubeadm.conf"
  }

  provisioner "file" {
    content     = "${tls_private_key.k8s_ca.private_key_pem}"
    destination = "ca.key"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.install-provisioner-script.rendered}"
  }
}

data "brightbox_image" "k8s_master" {
  name        = "${var.image_desc}"
  arch        = "x86_64"
  official    = true
  most_recent = true
}

data "template_file" "master-cloud-config" {
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
