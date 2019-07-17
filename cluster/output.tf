output "group_id" {
  value       = brightbox_server_group.k8s.id
  description = "Server Group for the Cluster"
}

output "firewall_policy_id" {
  value       = brightbox_firewall_policy.k8s.id
  description = "Firewal Policy for the Cluster"
}

