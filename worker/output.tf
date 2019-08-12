output "node_ids" {
  value = brightbox_server.k8s_worker[*].id
  description = "List of this modules node ids"
}
