terraform {
  required_providers {
    # https://registry.terraform.io/providers/signalsciences/sigsci/latest
    sigsci = {
      source  = "signalsciences/sigsci"
      version = ">= 3.0.0"
    }
  }
}
