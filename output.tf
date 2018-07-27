output "master" {
  value = "${brightbox_server.k8s_master.*.fqdn}"
}
