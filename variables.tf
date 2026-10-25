# Brightbox Cloud Region

variable "region" {
  type        = string
  description = "Brightbox region to connect to"
  default     = "gb1"
}

# Brightbox Account Details

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


# Cluster Details

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

variable "management_source" {
  description = "CIDR of any external management workstations. The default is no external workstations"
  type        = list(string)
  default     = ["0.0.0.0/32"]
}

variable "secure_kubelet" {
  description = "Ask kubelet to request a signing certificate from the master, rather than self-signing. Requires manual approval of certificates"
  type        = bool
  default     = false
}

variable "dual_stack" {
  description = "Run the cluster dual stack (IPv4 and IPv6). Set to false to build and maintain an IPv4-only cluster, with IPv6 disabled on the nodes"
  type        = bool
  default     = true
}

variable "additional_server_groups" {
  description = "Additional server group ids to add all cluster nodes to"
  type        = list(string)
  default     = []
}

# Masters

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

variable "master_zone" {
  type        = string
  description = "The zone in which the master nodes should be built. The default is to spread them across all zones."
  default     = ""
}

# Worker Nodes

variable "worker_root_size" {
  type        = number
  description = "The size of the root partition on worker nodes"
  default     = 0
}
variable "worker_count" {
  type        = number
  description = "Minimum number of worker nodes in cluster"
  default     = 1
}

variable "worker_max" {
  type        = number
  description = "Maximum number of worker nodes in cluster"
  default     = 0
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

# Storage Nodes

variable "storage_root_size" {
  type        = number
  description = "The size of the root partition on worker nodes"
  default     = 0
}

variable "storage_count" {
  type        = number
  description = "Minimum number of storage nodes in cluster"
  default     = 0
}

variable "storage_max" {
  type        = number
  description = "Maximum number of storage nodes in cluster"
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

variable "storage_system" {
  type        = string
  description = "The storage system you wish to use (manual, openebs). Automatically sets up the storage partition in the correct format and location."
  default     = "manual"
}

# Releases

variable "kubernetes_release" {
  type        = string
  description = "Version of Kubernetes to install"
  default     = "1.35.2"
}

variable "critools_release" {
  type        = string
  description = "Version of cri-tools to install. Defaults to the Kubernetes minor version, or 1.25 for releases older than 1.24"
  default     = null

  validation {
    condition = var.critools_release == null || (
      tonumber(split(".", var.kubernetes_release)[1]) >= 24
      ? var.critools_release == join(".", slice(split(".", var.kubernetes_release), 0, 2))
      : contains(["1.25", "1.26"], coalesce(var.critools_release, "unset"))
    )
    error_message = "critools_release must match the kubernetes_release minor version (or be 1.25/1.26 for releases older than 1.24); leave it unset to choose automatically."
  }
}

variable "autoscaler_release" {
  type        = string
  description = "Version of Vertical Autoscaler to install if the scaling features are activated. This needs to be the same minor version as the k8s release"
  default     = "1.35.0"
}

variable "calico_release" {
  type        = string
  description = "Version of Calico plugin to install. Defaults to the release tested with the chosen Kubernetes minor version (see calico_releases in main.tf)"
  default     = null

  validation {
    condition     = var.calico_release != null || contains(keys(local.calico_releases), join(".", slice(split(".", var.kubernetes_release), 0, 2)))
    error_message = "No default Calico release is known for this kubernetes_release; set calico_release explicitly."
  }
}

# Container Registry
variable "container_registry" {
  type        = string
  description = "container registry path"
  default     = "cr.brightbox.com/acc-juq13/public"
}

# Boot image search string

variable "image_desc" {
  type        = string
  description = "Image pattern to use to select boot image"
  default     = "^ubuntu-noble.*server$"
}
