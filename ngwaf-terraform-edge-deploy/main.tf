# Configure the Fastly Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend-vcl-service" {
  name = "Frontend VCL Service - NGWAF edge deploy"

  domain {
    name    = var.USER_VCL_SERVICE_DOMAIN_NAME
    comment = "Frontend VCL Service - NGWAF edge deploy"
  }
  backend {
    address = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    name = "vcl_service_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    ssl_sni_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    override_host = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
  }

#   #### Only disable caching for testing. Do not disable caching for production traffic.
#   snippet {
#     name = "Disable caching"
#     content = file("${path.module}/vcl/disable_caching.vcl")
#     type = "recv"
#     priority = 100
#   }

  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - Start
#   dynamicsnippet {
#     name     = "ngwaf_config_init"
#     type     = "init"
#     priority = 0
#   }
#   dynamicsnippet {
#     name     = "ngwaf_config_miss"
#     type     = "init"
#     priority = 150
#   }
#   dynamicsnippet {
#     name     = "ngwaf_config_pass"
#     type     = "init"
#     priority = 150
#   }
  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - End

  # dictionary {
  #   name       = var.Edge_Security_dictionary
  # }

  lifecycle {
    ignore_changes = [
      # dictionary,
      # dynamicsnippet,
      product_enablement,
    ]
  }

  force_destroy = true
}

# resource "fastly_service_dictionary_items" "edge_security_dictionary_items" {
#   for_each = {
#   for d in fastly_service_vcl.frontend-vcl-service.dictionary : d.name => d if d.name == var.Edge_Security_dictionary
#   }
#   service_id = fastly_service_vcl.frontend-vcl-service.id
#   dictionary_id = each.value.dictionary_id

#   items = {
#     Enabled: "100"
#   }
# }

#### Fastly VCL Service - End


provider "sigsci" {
  corp = var.NGWAF_CORP
  email = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
  fastly_key = var.FASTLY_API_KEY
}

resource "sigsci_edge_deployment" "ngwaf_edge_site_service" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment
  site_short_name = var.NGWAF_SITE
}

resource "sigsci_edge_deployment_service" "ngwaf_edge_service_link" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment_service
  site_short_name = var.NGWAF_SITE
  fastly_sid      = fastly_service_vcl.frontend-vcl-service.id
}

#### Edge deploy and sync - End

output "live_laugh_love_ngwaf" {
  value = "curl -i https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs"
}
