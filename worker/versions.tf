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
    template = {
      source  = "hashicorp/template"
      version = "~> 2.1"
    }
  }
  required_version = ">= 0.12"
}
