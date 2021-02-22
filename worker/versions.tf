terraform {
  required_providers {
    brightbox = {
      source  = "brightbox/brightbox"
      version = "~> 1.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1.2"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.1.2"
    }
  }
  required_version = ">= 0.12"
}
