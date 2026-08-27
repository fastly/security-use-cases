#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend_vcl_service" {
  # provider = fastly.primary
  name     = "Frontend VCL Service - edge deploy ${var.SERVICE_VCL_FRONTEND_DOMAIN_NAME}"

  domain {
    name    = var.SERVICE_VCL_FRONTEND_DOMAIN_NAME
    comment = "Frontend VCL Service - edge deploy"
  }

  product_enablement {
    api_discovery         = true
    brotli_compression    = false
    domain_inspector      = true
    image_optimizer       = false
    log_explorer_insights = true
    origin_inspector      = true
    websockets            = false
    bot_management {
      contentguard = "on"
      enabled      = true
    }
    ddos_protection {
      enabled = true
      mode    = "log"
    }
    ngwaf {
      enabled      = true
      traffic_ramp = 100
      workspace_id = var.NGWAF_WORKSPACE_ID
    }
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

  force_destroy = true
}

#### Fastly VCL Service - End

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
