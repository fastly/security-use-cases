provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

module "edge_security" {
  source = "../modules/edge-security"
}

module "service_vcl" {
  source                           = "../modules/service-vcl"
  FASTLY_API_KEY                   = var.FASTLY_API_KEY
  SERVICE_VCL_FRONTEND_DOMAIN_NAME = var.SERVICE_VCL_FRONTEND_DOMAIN_NAME
  SERVICE_VCL_BACKEND_HOSTNAME     = var.SERVICE_VCL_BACKEND_HOSTNAME
  NGWAF_WORKSPACE_ID               = module.edge_security.ngwaf_workspace_id
  providers = {
    fastly = fastly
  }
}

output "live_waf_love" {
  value = module.service_vcl.vcl_service_output
}
