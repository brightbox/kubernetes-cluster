variable "region" {
  type        = string
  description = "Brightbox region to connect to"
}

variable "kubernetes_release" {
  type        = string
  description = "Version of Kubernetes to install"
}

variable "critools_release" {
  type        = string
  description = "Version of cri-tools to install"
}

variable "calico_release" {
  type        = string
  description = "Version of Calico to install"
}

variable "autoscaler_release" {
  type        = string
  description = "Version of autoscaler to install"
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
}

variable "cluster_server_group" {
  type        = string
  description = "The cluster server group to place master nodes in"
}

variable "cluster_firewall_policy" {
  type        = string
  description = "The cluster firewall policy to place load balancer rules in"
}

variable "cluster_name" {
  type        = string
  description = "Internal Cluster name"
}

variable "cluster_domainname" {
  type        = string
  description = "Internal Cluster domain name"
}

variable "apiserver_service_port" {
  type        = string
  description = "Apiserver service port number"
}

variable "ca_cert_pem" {
  type        = string
  description = "PEM format certificate to use as CA on masters"
}

variable "ca_private_key_pem" {
  type        = string
  description = "PEM format certificate to use as CA private key on masters"
}

variable "cluster_ready" {
  description = "resource that indicates the cluster containers are ready "
}

variable "cluster_cidr" {
  type        = string
  description = "CIDR to assign to the cluster overlay network"
}

variable "service_cidr" {
  type        = string
  description = "CIDR to assign to the service overlay network"
}

variable "storage_system" {
  type        = string
  description = "Which storage system support manifests to install"
}

variable "manage_autoscaler" {
  type        = bool
  description = "Whether to install and manage the vertical autoscaler"
}

variable "secure_kubelet" {
  type        = bool
  description = "Whether to ask for a central signing certificate or stick with self-signed"
}

variable "additional_server_groups" {
  description = "Additional server group ids to add all cluster nodes to"
  type        = list(string)
  default     = []
}

variable "container_registry" {
  type        = string
  description = "path to the container registry to use"
}
