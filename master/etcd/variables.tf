variable "servers" {
  type        = list(object({ address = string, username = string, id = string }))
  description = "The set of host name/address keys and logon user values"
}

variable "bastion" {
  type        = string
  description = "Baston host name/address"
  default     = ""
}

variable "bastion_user" {
  type        = string
  description = "Baston host username"
  default     = ""
}

variable "validity_period" {
  type        = number
  description = "CA Certificate validity period"
}

variable "renew_period" {
  type        = number
  description = "CA Certificate validity period"
}

variable "organizational_unit" {
  type        = string
  description = "OU to assign to etcd CA certificate"
}

variable "new_cluster" {
  type        = bool
  description = "Do we need to bootstrap an entirely new etcd cluster?"
}

variable "deps" {
  type = list
  default = []
}
