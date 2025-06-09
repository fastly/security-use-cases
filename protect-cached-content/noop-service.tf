#### Fastly VCL Service - Start
resource "fastly_service_vcl" "noop-vcl-service" {
  name = "Frontend VCL Service - NGWAF edge deploy ${var.USER_NOOP_SERVICE_DOMAIN_NAME}"

  product_enablement {
    origin_inspector      = true
    domain_inspector      = true
    bot_management        = true
    log_explorer_insights = true
  }
  domain {
    name    = var.USER_NOOP_SERVICE_DOMAIN_NAME
    comment = "Frontend VCL Service - NGWAF edge deploy"
  }

  snippet {
    name     = "noop response caching"
    content  = file("${path.module}/vcl/noop.vcl")
    type     = "init"
    priority = 100
  }

  force_destroy = true
}

output "noop_output" {
  value = <<tfmultiline
  
  #### Click the URL to go to the Fastly VCL service ####
  https://cfg.fastly.com/${fastly_service_vcl.noop-vcl-service.id}

  tfmultiline

  description = "Output hints on what to do next."
}

