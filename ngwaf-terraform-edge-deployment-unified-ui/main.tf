resource "fastly_service_vcl" "frontend_vcl_service" {
  name = "NGWAF edge deploy ${var.USER_VCL_SERVICE_DOMAIN_NAME}"
  activate = true

  domain {
    name    = var.USER_VCL_SERVICE_DOMAIN_NAME
    comment = "Frontend VCL Service - NGWAF edge deploy"
  }
  product_enablement {
    ngwaf {
      traffic_ramp = 100
      workspace_id = fastly_ngwaf_workspace.my_ngwaf_workspace.id
      enabled = true
    }
  }

  backend {
    address           = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    name              = "vcl_service_origin"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    ssl_sni_hostname  = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    override_host     = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
  }

  force_destroy = true
}
