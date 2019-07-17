variable "region" {
  type        = string
  description = "Brightbox region to connect to"
  default     = "gb1"
}

variable "username" {
  type        = string
  description = "Brightbox account username"
}

variable "password" {
  type        = string
  description = "Brightbox account password"
}

variable "account" {
  type        = string
  description = "Brightbox account name"
}

variable "apiclient" {
  type        = string
  description = "Brightbox API application client id"
  default     = "app-dkmch"
}

variable "apisecret" {
  type        = string
  description = "Brightbox API application shared secret"
  default     = "uogoelzgt0nwawb"
}

variable "master_count" {
  type        = number
  description = "Number of master servers in cluster"
  default     = 1
}

variable "master_type" {
  type        = string
  description = "Type of server to use as k8s master node"
  default     = "2gb.ssd"
}

variable "management_source" {
  description = "CIDR of any external management workstations"
  type        = list
  default     = ["0.0.0.0/32"]
}

variable "image_desc" {
  type        = string
  description = "Image pattern to use to select boot image"
  default     = "^ubuntu-bionic.*server$"
}

variable "worker_count" {
  type        = number
  description = "Number of worker servers in cluster"
  default     = 1
}

variable "worker_type" {
  type        = string
  description = "Type of server to use as k8s worker node"
  default     = "2gb.ssd"
}

variable "worker_drain_timeout" {
  type        = string
  description = "How long to wait for pods to move off a node before it is deleted"
  default     = "120s"
}

variable "worker_vol_count" {
  type        = number
  description = "The number of Permanent Volumes to create on each node"
  default     = 1
}

variable "cluster_domainname" {
  type        = string
  description = "internal domain name of the Kubernetes Cluster"
  default     = "cluster.local"
}

variable "cluster_name" {
  type        = string
  description = "name of this Kubernetes Cluster - used to mark server descriptions"
  default     = "kubernetes"
}

variable "reclaim_volumes" {
  type        = bool
  description = "Whether to delete local volumes after a pod has used them, or retain them on the node. Defaults to retain"
  default     = false
}

# Releases

variable "kubernetes_release" {
  type        = string
  description = "Version of Kubernetes to install"
  default     = "1.14.3"
}

variable "calico_release" {
  type        = string
  description = "Version of Calico plugin to install"
  default     = "3.7"
}

