resource "null_resource" "etcd_configure" {
  count = length(var.servers)

  connection {
    host         = var.servers[count.index].address
    user         = var.servers[count.index].username
    type         = "ssh"
    bastion_host = var.bastion
    bastion_user = var.bastion_user
  }

  provisioner "remote-exec" {
    inline = [
      "uname -a"
    ]
  }
}
