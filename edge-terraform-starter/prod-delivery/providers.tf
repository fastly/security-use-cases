terraform {
  required_providers {
    fastly = {
      source  = "fastly/fastly"
      version = ">= 5.7.0"
    #   configuration_aliases = [ fastly ]
    }
    sigsci = {
      source  = "signalsciences/sigsci"
      version = ">= 2.1.0"
    #   configuration_aliases = [ sigsci ]
    }
  }
}