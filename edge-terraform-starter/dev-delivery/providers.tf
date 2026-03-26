terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = ">= 5.7.0"
    }
    sigsci = {
      source  = "signalsciences/sigsci"
      version = ">= 2.1.0"
    }
  }
}
