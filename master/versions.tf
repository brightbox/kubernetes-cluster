terraform {
  required_providers {
    brightbox = {
      source  = "brightbox/brightbox"
      version = "~> 1.4.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 2.3.0"
    }
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 1.22.1"
    }
  }
  required_version = ">= 0.12"
}
