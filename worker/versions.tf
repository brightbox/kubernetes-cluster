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
  }
  required_version = ">= 0.12"
}
