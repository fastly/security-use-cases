# Terraform 0.13+ requires providers to be declared in a "required_providers" block
# https://registry.terraform.io/providers/fastly/fastly/latest/docs
terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = ">= 3.0.4"
    }
  }
}
