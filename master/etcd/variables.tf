variable "servers" {
  type        = list(object({ address = string, username = string }))
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
