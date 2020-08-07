
terraform {
  required_providers {
    brightbox = {
      source  = "brightbox/brightbox"
      version = "~> 1.4.0"
    }
  }
  required_version = "~> 0.12.0"
}

provider "brightbox" {
  apiurl    = "https://api.${var.region}.brightbox.com"
  username  = var.username
  password  = var.password
  account   = var.account
  apiclient = var.apiclient
  apisecret = var.apisecret
}

provider "null" {
  version = "~> 2.0"
}

provider "random" {
  version = "~> 2.0"
}

provider "tls" {
  version = "~> 2.0.1"
}

provider "template" {
  version = "~> 2.1"
}
