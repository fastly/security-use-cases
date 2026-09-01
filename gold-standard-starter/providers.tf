terraform {
  required_providers {
    # https://registry.terraform.io/providers/fastly/fastly/latest/docs
    fastly = {
      source  = "fastly/fastly"
      version = ">= 9.3.0"
    }
  }
}
