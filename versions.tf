
terraform {
  required_providers {
    brightbox = {
      source  = "brightbox/brightbox"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.2, < 5.0"
    }
  }
  # Variable validations refer to other variables, which needs Terraform 1.9+.
  # OpenTofu checks this constraint against its own version.
  required_version = ">= 1.9.0"
}

provider "brightbox" {
  apiurl    = "https://api.${var.region}.brightbox.com"
  username  = var.username
  password  = var.password
  account   = var.account
  apiclient = var.apiclient
  apisecret = var.apisecret
}

