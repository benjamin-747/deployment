terraform {
  required_version = ">= 1.15.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.20, < 3.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.12, < 3.0.0"
    }
  }
}
