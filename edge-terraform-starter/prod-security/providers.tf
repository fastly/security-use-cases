terraform {
  required_providers {
    # https://registry.terraform.io/providers/signalsciences/sigsci/latest
    sigsci = {
      source = "signalsciences/sigsci"
	  version = ">= 2.1.0"
    }
  }
}