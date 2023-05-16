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

  #### Adds the necessary header to enable response headers from the NGWAF edge deployment, which may then be used for logging. 
  # Also, removes the sensitive response headers before delivering the response to the client
  
  snippet {
    name = "Add ngwaf log headers"
    content = file("${path.module}/vcl/add_ngwaf_log_headers.vcl")
    type = "recv"
    priority = 110
  }

  #### Only disable caching for testing. Do not disable caching for production traffic.
  snippet {
    name = "Disable caching"
    content = file("${path.module}/vcl/disable_caching.vcl")
    type = "recv"
    priority = 100
  }

  #### Useful for debugging with response headers
  # snippet {
  #   name = "Debug headers"
  #   content = file("${path.module}/vcl/debug_headers.vcl")
  #   type = "fetch"
  #   priority = 120
  # }

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
    name       = var.Edge_Security_dictionary
  }

  logging_honeycomb {
    dataset = "NGWAF_EDGE_DATASET"
    name = "NGWAF_EDGE_LOGS"
    token = var.HONEYCOMB_API_KEY
    format = file("${path.module}/ngwaf_logging_format.json")
  }

  lifecycle {
    ignore_changes = [
      product_enablement,
    ]
  }

  force_destroy = true
}

resource "fastly_service_dictionary_items" "edge_security_dictionary_items" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dictionary : d.name => d if d.name == var.Edge_Security_dictionary
  }
  service_id = fastly_service_vcl.frontend-vcl-service.id
  dictionary_id = each.value.dictionary_id

  items = {
    Enabled: "100"
  }
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_init" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_init"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_init"
  
  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_miss" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_miss"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_miss"

  manage_snippets = false
}

resource "fastly_service_dynamic_snippet_content" "ngwaf_config_pass" {
  for_each = {
  for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_pass"
  }

  service_id = fastly_service_vcl.frontend-vcl-service.id
  snippet_id = each.value.snippet_id

  content = "### Fastly managed ngwaf_config_pass"

  manage_snippets = false
}

# resource "fastly_service_dynamic_snippet_content" "ngwaf_config_deliver" {
#   for_each = {
#   for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "ngwaf_config_deliver"
#   }

#   service_id = fastly_service_vcl.frontend-vcl-service.id
#   snippet_id = each.value.snippet_id

#   content = "### Fastly managed ngwaf_config_deliver"

#   manage_snippets = false
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
    provisioner "local-exec" {
      command = "echo 'Sleep for 100 seconds'; sleep 100"
  }
}

resource "sigsci_edge_deployment_service" "ngwaf_edge_service_link" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment_service
  site_short_name = var.NGWAF_SITE
  fastly_sid      = fastly_service_vcl.frontend-vcl-service.id

  activate_version = true
  percent_enabled = 100

  depends_on = [
    sigsci_edge_deployment.ngwaf_edge_site_service,
    fastly_service_vcl.frontend-vcl-service,
  ]
}

# resource "sigsci_edge_deployment_service_backend" "ngwaf_edge_service_backend_sync" {
#   site_short_name = var.NGWAF_SITE
#   fastly_sid      = fastly_service_vcl.frontend-vcl-service.id

#   fastly_service_vcl_active_version = fastly_service_vcl.frontend-vcl-service.active_version

#   depends_on = [
#     sigsci_edge_deployment_service.ngwaf_edge_service_link,
#   ]
# }

#### Edge deploy and sync - End

output "live_laugh_love_ngwaf" {
  value = <<tfmultiline
  
  #### Click the URL to go to the Fastly VCL service ####
  https://cfg.fastly.com/${fastly_service_vcl.frontend-vcl-service.id}

  #### Click the URL to go to the Fastly NGWAF service ####
  https://dashboard.signalsciences.net/corps/${var.NGWAF_CORP}/sites/${var.NGWAF_SITE}
  
  #### Send a test request with curl. ####
  curl -i "https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs" -d foo=bar

  #### Send an test as traversal with curl. ####
  curl -i "https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/myattackreq?i=../../../../etc/passwd'" -d foo=bar


  #### Troubleshoot the logging configuration if necessary. ####
  https://docs.fastly.com/en/guides/setting-up-remote-log-streaming#troubleshooting-common-logging-errors
  curl https://api.fastly.com/service/${fastly_service_vcl.frontend-vcl-service.id}/logging_status -H fastly-key:$FASTLY_API_KEY
  
  tfmultiline

  description = "Output hints on what to do next."

  depends_on = [
    sigsci_edge_deployment_service.ngwaf_edge_service_link
  ]
}
