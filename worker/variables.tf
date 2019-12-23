variable "boot_token" {
  type        = string
  description = "The shared secret used to connect to the cluster control plane"
}

variable "region" {
  type        = string
  description = "Brightbox region to connect to"
}

variable "kubernetes_release" {
  type        = string
  description = "Version of Kubernetes to install"
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
  description = "Number of worker nodes"
}

variable "worker_min" {
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

variable "internal_cluster_fqdn" {
  type        = string
  description = "Internal Cluster domain name"
}

variable "apiserver_fqdn" {
  type        = string
  description = "ApiServer domain name"
}

variable "apiserver_service_port" {
  type        = string
  description = "Apiserver service port number"
}

variable "ca_cert_pem" {
  type        = string
  description = "PEM format certificate to use as CA on workers"
}

variable "bastion" {
  type        = string
  description = "Publicly accessible host to use to configure workers from"
}

variable "bastion_user" {
  type        = string
  description = "Logon ID on Bastion Host"
}

variable "worker_drain_timeout" {
  type        = string
  description = "How long to wait for worker to drain pods as a kubeadm time spec"
}

variable "apiserver_ready" {
  type        = list(string)
  description = "resource that indicates the apiserver is ready to receive instructions"
}

variable "cluster_ready" {
  description = "resource that indicates the cluster containers are ready "
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
