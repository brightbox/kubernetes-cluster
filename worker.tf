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
    inline = "${data.template_file.install-provisioner-script.rendered}"
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
  template = "${file("${local.template_path}/worker-cloud-config.yml")}"
}

data "template_file" "worker-provisioner-script" {
  template = "${file("${local.template_path}/install-worker")}"
}
