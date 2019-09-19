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
  description = "Number of worker nodes in cluster"
  default     = 1
}

variable "worker_type" {
  type        = string
  description = "Type of server to use as k8s worker node"
  default     = "2gb.ssd"
}

variable "worker_name" {
  type        = string
  description = "The name given to worker nodes on the cluster"
  default     = "k8s-worker"
}

variable "worker_zone" {
  type        = string
  description = "The zone in which the worker nodes should be built. The default is to spread them across all zones."
  default     = ""
}

variable "worker_drain_timeout" {
  type        = string
  description = "How long to wait for pods to move off a node before it is deleted"
  default     = "120s"
}

variable "worker_cloudip_count" {
  type        = number
  description = "Number of workers to allocate fixed cloud ips to"
  default     = 0
}

variable "storage_count" {
  type        = number
  description = "Number of storage nodes in cluster"
  default     = 0
}

variable "storage_type" {
  type        = string
  description = "Type of node to use as k8s storage node"
  default     = "2gb.ssd"
}

variable "storage_name" {
  type        = string
  description = "The name given to storage nodes on the cluster"
  default     = "k8s-storage"
}

variable "storage_zone" {
  type        = string
  description = "The zone in which the storage nodes should be built. The default is to spread them across all zones."
  default     = ""
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

# Releases

variable "kubernetes_release" {
  type        = string
  description = "Version of Kubernetes to install"
  default     = "1.15.4"
}

variable "calico_release" {
  type        = string
  description = "Version of Calico plugin to install"
  default     = "3.8"
}

variable "openebs_release" {
  type        = string
  description = "Version of OpenEBS namespace to install"
  default     = "1.0.0"
}
