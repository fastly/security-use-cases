# Terraform 0.13+ requires providers to be declared in a "required_providers" block
# https://registry.terraform.io/providers/fastly/fastly/latest/docs
terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = ">= 5.11.0"
    }
    sigsci = {
      source  = "signalsciences/sigsci"
      version = ">= 3.3.0"
    }
    http = {
      source = "hashicorp/http"
    }
  }
}
