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

variable "server_groups" {
  type        = list(string)
  description = "List of Server Groups Ids in which worker nodes will be built"
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

variable "master_ready" {
  type        = object({ id = string })
  description = "resource that indicates the master is ready to receive instructions"
}

variable "cluster_ready" {
  description = "resource that indicates the cluster containers are ready "
}

