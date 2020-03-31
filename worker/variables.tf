variable "region" {
  type        = string
  description = "Brightbox region to connect to"
}

variable "root_size" {
  type        = number
  description = "The size of the worker root partition in GiB (0 for full size)"
}

variable "internal_cluster_fqdn" {
  type        = string
  description = "Internal Cluster domain name"
}

variable "image_desc" {
  type        = string
  description = "Image pattern to use to select boot image"
}

variable "worker_type" {
  type        = string
  description = "Server type of worker nodes"
}

variable "worker_count" {
  type        = number
  description = "Minimum number of worker nodes"
}

variable "worker_max" {
  type        = number
  description = "Maximum number of worker nodes"
}

variable "cluster_server_group" {
  type        = string
  description = "The cluster server group to place worker nodes in"
}

variable "bastion" {
  type        = string
  description = "Publicly accessible host to use to configure workers from"
}

variable "bastion_user" {
  type        = string
  description = "Logon ID on Bastion Host"
}

variable "worker_name" {
  type        = string
  description = "The name prefix of the worker in this group"
  default     = "k8s-worker"
}

variable "worker_zone" {
  type        = string
  description = "The zone the workers are to be built in: 'a' or 'b'. Default is to spread between the zones"
  default     = ""
}

variable "cluster_ready" {
  description = "resource that indicates the cluster containers are ready "
}
