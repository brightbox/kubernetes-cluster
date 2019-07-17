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

variable "cloud_config" {
  type        = string
  description = "Injected common cloud configuration script"
}

variable "install_script" {
  type        = string
  description = "Injected common install script"
}

variable "kubeadm_config_script" {
  type        = string
  description = "Injected kubeadm config script"
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

variable "worker_vol_count" {
  type        = number
  description = "Number of local volumes to create on each worker node"
}

variable "apiserver_ready" {
  type        = object({ id = string })
  description = "resource that indicates the apiserver is ready to receive instructions"
}

variable "cluster_ready" {
  description = "resource that indicates the cluster containers are ready "
}

variable "worker_name" {
  type =string
  description = "The name prefix of the worker in this group"
  default = "k8s-worker"
}

variable "worker_zone" {
  type = string
  description = "The zone the workers are to be built in: 'a' or 'b'. Default is to spread between the zones"
  default = ""
}
