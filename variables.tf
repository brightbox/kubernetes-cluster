variable "region" {
  description = "Brightbox region to connect to"
  default     = "gb1"
}

variable "username" {
  description = "Brightbox account username"
}

variable "password" {
  description = "Brightbox account password"
}

variable "account" {
  description = "Brightbox account name"
}

variable "apiclient" {
  description = "Brightbox API Client ID for building nodes"
  default     = "app-dkmch"
}

variable "apisecret" {
  description = "Secret for the node building API Client ID"
  default     = "uogoelzgt0nwawb"
}

variable "controller_client" {
  description = "Brightbox API Client ID for the Brightbox cloud controller app"
}

variable "controller_client_secret" {
  description = "Secret for the Controller API Client ID"
}

variable "master_count" {
  description = "Number of master servers in cluster"
  default     = 1
}

variable "master_type" {
  description = "Type of server to use as k8s master node"
  default     = "2gb.ssd"
}

variable "management_source" {
  description = "CIDR of any external management workstations"
  default     = "0.0.0.0/32"
}

variable "image_desc" {
  description = "Image pattern to use to select boot image"
  default     = "^ubuntu-bionic.*server$"
}

variable "worker_count" {
  description = "Number of worker servers in cluster"
  default     = 1
}

variable "worker_type" {
  description = "Type of server to use as k8s worker node"
  default     = "2gb.ssd"
}

variable "worker_drain_timeout" {
  description = "How long to wait for pods to move off a node before it is deleted"
  default     = "60s"
}

variable "cluster_domainname" {
  description = "internal domain name of the Kubernetes Cluster"
  default     = "cluster.local"
}

variable "cluster_name" {
  description = "name of this Kubernetes Cluster - used to mark server descriptions"
  default     = "kubernetes"
}

# Releases

#variable "k8s_release" {
#  description = "Version of kubernetes to use"
#  default     = "v1.11.0"
#}

variable "critools_release" {
  description = "Version of critools to use"
  default     = "v1.11.1"
}

variable "cni_plugins_release" {
  description = "Version of cniplugins to use"
  default     = "v0.7.1"
}

variable "containerd_release" {
  description = "Version of containerd to use"
  default     = "1.1.2"
}

variable "brightbox_cloud_controller_release" {
  description = "Version of Brightbox cloud controller to use"
  default     = "0.0.7"
}

variable "runc_release" {
  description = "Version of runc to use"
  default     = "v1.0.0-rc5"
}
