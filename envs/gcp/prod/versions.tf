terraform {
  required_version = ">= 1.14.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.26.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 7.26.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
  }
}
