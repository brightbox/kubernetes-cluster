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

variable "bastion" {
  description = "Bastion host name to use"
}

variable "master_type" {
  description = "Type of server to use as k8s master node"
  default     = "1gb.ssd"
}

variable "worker_count" {
  description = "Number of worker servers in cluster"
  default     = 1
}

variable "image_desc" {
  description = "Image pattern to use to select boot image"
  default     = "^ubuntu-bionic.*server$"
}

variable "worker_type" {
  description = "Type of server to use as k8s worker node"
  default     = "1gb.ssd"
}

variable "k8s_release" {
  description = "Version of kubernetes to use"
  default     = "v1.10.4"
}

variable "critools_release" {
  description = "Version of critools to use"
  default     = "v1.0.0-beta.1"
}

variable "cni_plugins_release" {
  description = "Version of cniplugins to use"
  default     = "v0.7.1"
}

variable "containerd_release" {
  description = "Version of containerd to use"
  default     = "1.1.0"
}

variable "brightbox_cloud_controller_release" {
  description = "Version of Brightbox cloud controller to use"
  default     = "0.0.1"
}

variable "runc_release" {
  description = "Version of runc to use"
  default     = "v1.0.0-rc5"
}
