variable "region" {
  type        = string
  description = "Brightbox region to connect to"
}

variable "internal_cluster_fqdn" {
  type        = string
  description = "Internal Cluster domain name"
}

variable "image_desc" {
  type        = string
  description = "Image pattern to use to select boot image"
}

variable "master_type" {
  type        = string
  description = "Server type of master nodes"
}

variable "master_count" {
  type        = number
  description = "Number of master nodes"
}

variable "master_zone" {
  type        = string
  description = "The zone the masters are to be built in: 'a' or 'b'. Default is to spread between the zones"
  default     = ""
}

variable "cluster_server_group" {
  type        = string
  description = "The cluster server group to place master nodes in"
}

variable "cluster_firewall_policy" {
  type        = string
  description = "The cluster firewall policy to place load balancer rules in"
}

variable "apiserver_service_port" {
  type        = string
  description = "Apiserver service port number"
}

variable "cluster_ready" {
  description = "resource that indicates the cluster containers are ready "
}

