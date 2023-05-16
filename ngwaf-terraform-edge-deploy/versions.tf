# Terraform 0.13+ requires providers to be declared in a "required_providers" block
# https://registry.terraform.io/providers/fastly/fastly/latest/docs
terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = ">= 3.0.4"
    }
    sigsci = {
      source = "signalsciences/sigsci"
      version = ">= 1.2.18"
      # source = "terraform.local/local/sigsci"
      # version = ">= 3.0.4"
    }
  }
}
