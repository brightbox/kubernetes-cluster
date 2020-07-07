resource "null_resource" "etcd_configure" {
  count = length(var.servers)

  connection {
    host         = var.servers[count.index].address
    user         = var.servers[count.index].username
    type         = "ssh"
    bastion_host = var.bastion
    bastion_user = var.bastion_user
  }

  provisioner "file" {
    content     = var.ca_cert_pem
    destination = "ca-etcd.crt"
  }

  provisioner "file" {
    content     = var.ca_private_key_pem
    destination = "ca-etcd.key"
  }


  provisioner "remote-exec" {
    inline = [
      "uname -a"
    ]
  }
}
