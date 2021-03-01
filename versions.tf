
terraform {
  required_providers {
    brightbox = {
      source  = "brightbox/brightbox"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 2.0"
    }
  }
  required_version = ">= 0.12"
}

provider "brightbox" {
  apiurl    = "https://api.${var.region}.brightbox.com"
  username  = var.username
  password  = var.password
  account   = var.account
  apiclient = var.apiclient
  apisecret = var.apisecret
}

