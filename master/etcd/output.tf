output "etcd_ready" {
  value       = local.etcd_configured
  description = "Resource pre-requisite that signals the etcd installation is complete"
}
