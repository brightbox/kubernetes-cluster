terraform {
  required_providers {
    brightbox = {
      source  = "brightbox/brightbox"
      version = "~> 3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
  required_version = ">= 0.12"
}
