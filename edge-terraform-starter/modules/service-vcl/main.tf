# Configure the Fastly Provider
# provider "fastly" {
#   api_key = var.FASTLY_API_KEY
# }

#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend_vcl_service" {
  # provider = fastly.primary
  name     = "Frontend VCL Service - edge deploy ${var.SERVICE_VCL_FRONTEND_DOMAIN_NAME}"

  domain {
    name    = var.SERVICE_VCL_FRONTEND_DOMAIN_NAME
    comment = "Frontend VCL Service - edge deploy"
  }
  backend {
    address           = var.SERVICE_VCL_BACKEND_HOSTNAME
    name              = "vcl_service_origin"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = var.SERVICE_VCL_BACKEND_HOSTNAME
    ssl_sni_hostname  = var.SERVICE_VCL_BACKEND_HOSTNAME
    override_host     = var.SERVICE_VCL_BACKEND_HOSTNAME
  }

  #### Disable caching, but keep request collapsing https://www.fastly.com/documentation/reference/vcl/variables/backend-response/beresp-cacheable/#effects-on-request-collapsing
  snippet {
    name     = "Disable caching"
    content  = "set beresp.cacheable = false;"
    type     = "fetch"
    priority = 9000
  }

  snippet {
    name     = "cdn enrichment"
    content  = file("${path.module}/vcl/cdn_enrichment.vcl")
    type     = "recv"
    priority = 110
  }

  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - Start
  dynamicsnippet {
    name     = "ngwaf_config_init"
    type     = "init"
    priority = 0
  }
  dynamicsnippet {
    name     = "ngwaf_config_miss"
    type     = "miss"
    priority = 9000
  }
  dynamicsnippet {
    name     = "ngwaf_config_pass"
    type     = "pass"
    priority = 9000
  }
  dynamicsnippet {
    name     = "ngwaf_config_deliver"
    type     = "deliver"
    priority = 9000
  }
  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - End

  dictionary {
    name = "Edge_Security"
  }

  force_destroy = true
}

resource "fastly_service_dictionary_items" "edge_security_dictionary_items" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dictionary : d.name => d if d.name == "Edge_Security"
  }
  service_id    = fastly_service_vcl.frontend_vcl_service.id
  dictionary_id = each.value.dictionary_id
  items = {
    Enabled : "100"
  }
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_init" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_init"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_init"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_miss" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_miss"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_miss"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_pass" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_pass"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_pass"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_deliver" {
  for_each = {
    for d in fastly_service_vcl.frontend_vcl_service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_deliver"
  }

  service_id = fastly_service_vcl.frontend_vcl_service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_deliver"

  manage_snippets = false
}

#### Fastly VCL Service - End

#### Edge deploy and sync - Start

# provider "sigsci" {
#   corp           = var.NGWAF_CORP
#   email          = var.NGWAF_EMAIL
#   auth_token     = var.NGWAF_TOKEN
#   fastly_api_key = var.FASTLY_API_KEY
# }

# resource "sigsci_edge_deployment" "ngwaf_edge_site_service" {
#   # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment
#   site_short_name = var.NGWAF_SITE
# }

resource "sigsci_edge_deployment_service" "ngwaf_edge_service_link" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment_service
  site_short_name = var.NGWAF_SITE
  fastly_sid      = fastly_service_vcl.frontend_vcl_service.id

  activate_version = true
  percent_enabled  = 100

  depends_on = [
    fastly_service_vcl.frontend_vcl_service,
    fastly_service_dictionary_items.edge_security_dictionary_items,
    fastly_service_dynamic_snippet_content.ngwaf_config_init,
    fastly_service_dynamic_snippet_content.ngwaf_config_miss,
    fastly_service_dynamic_snippet_content.ngwaf_config_pass,
    fastly_service_dynamic_snippet_content.ngwaf_config_deliver,
  ]
}

#### Edge deploy and sync - End

output "vcl_service_output" {
  value = <<tfmultiline
  
  #### Click the URL to go to the Fastly VCL service ####
  https://cfg.fastly.com/${fastly_service_vcl.frontend_vcl_service.id}
  
  #### Send a test request with curl. ####
  curl -i "https://${var.SERVICE_VCL_FRONTEND_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs" -d foo=bar

  #### Send an test as traversal with curl. ####
  curl -i "https://${var.SERVICE_VCL_FRONTEND_DOMAIN_NAME}/anything/myattackreq?i=../../../../etc/passwd'" -d foo=bar

  #### Troubleshoot the logging configuration if necessary. ####
  https://docs.fastly.com/en/guides/setting-up-remote-log-streaming#troubleshooting-common-logging-errors
  curl https://api.fastly.com/service/${fastly_service_vcl.frontend_vcl_service.id}/logging_status -H fastly-key:$FASTLY_API_KEY
  
  tfmultiline

  description = "Output hints on what to do next."

}
