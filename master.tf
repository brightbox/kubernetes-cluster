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
}

resource "null_resource" "k8s_master" {
  triggers {
    master_id = "${brightbox_server.k8s_master.id}"
  }

  connection {
    user         = "${brightbox_server.k8s_master.username}"
    host         = "${brightbox_server.k8s_master.ipv6_hostname}"
    bastion_host = "${var.bastion}"
  }

  provisioner "file" {
    content     = "${tls_self_signed_cert.k8s_ca.cert_pem}"
    destination = "ca.crt"
  }

  provisioner "file" {
    content     = "${tls_self_signed_cert.k8s_etcd_ca.cert_pem}"
    destination = "etcd_ca.crt"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.etcd-peer.cert_pem}"
    destination = "etcd_peer.crt"
  }

  provisioner "file" {
    content     = "${tls_private_key.etcd-peer.private_key_pem}"
    destination = "etcd_peer.key"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.etcd-server.cert_pem}"
    destination = "etcd_server.crt"
  }

  provisioner "file" {
    content     = "${tls_private_key.etcd-server.private_key_pem}"
    destination = "etcd_server.key"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.etcd-healthcheck-client.cert_pem}"
    destination = "etcd_healthcheck-client.crt"
  }

  provisioner "file" {
    content     = "${tls_private_key.etcd-healthcheck-client.private_key_pem}"
    destination = "etcd_healthcheck-client.key"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.apiserver-etcd-client.cert_pem}"
    destination = "apiserver-etcd-client.crt"
  }

  provisioner "file" {
    content     = "${tls_private_key.apiserver-etcd-client.private_key_pem}"
    destination = "apiserver-etcd-client.key"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.apiserver-kubelet-client.cert_pem}"
    destination = "apiserver-kubelet-client.crt"
  }

  provisioner "file" {
    content     = "${tls_private_key.apiserver-kubelet-client.private_key_pem}"
    destination = "apiserver-kubelet-client.key"
  }

  provisioner "file" {
    content     = "${tls_locally_signed_cert.apiserver.cert_pem}"
    destination = "apiserver.crt"
  }

  provisioner "file" {
    content     = "${tls_private_key.apiserver.private_key_pem}"
    destination = "apiserver.key"
  }

  provisioner "file" {
    content     = "${tls_private_key.k8s_sa.public_key_pem}"
    destination = "sa.pub"
  }

  provisioner "file" {
    content     = "${tls_private_key.k8s_sa.private_key_pem}"
    destination = "sa.key"
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

  provisioner "file" {
    content     = "${tls_private_key.k8s_etcd_ca.private_key_pem}"
    destination = "etcd_ca.key"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.install-provisioner-script.rendered}"
  }

  provisioner "remote-exec" {
    inline = "${data.template_file.master-provisioner-script.rendered}"
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

data "template_file" "master-provisioner-script" {
  template = "${file("${path.root}/templates/install-master")}"

  vars {
    cluster_domainname       = "${var.cluster_domainname}"
    hostname                 = "${brightbox_server.k8s_master.hostname}"
    external_ip              = "${brightbox_server.k8s_master.ipv6_address}"
    service_cluster_ip_range = "fd00:1234::/112"
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
