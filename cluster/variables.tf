variable "cluster_fqdn" {
  type        = string
  description = "Cluster Domain Name"
}

variable "management_source" {
  type        = list(string)
  description = "List of Management source CIDR Addresses"
}

variable "service_port" {
  type        = string
  description = "K8s apiserver service port number"
}
