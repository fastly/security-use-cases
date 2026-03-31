provider "sigsci" {
  corp       = var.NGWAF_CORP
  email      = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
}

provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

module "service_vcl" {
  for_each                         = var.domains
  source                           = "../modules/service-vcl"
  FASTLY_API_KEY                   = var.FASTLY_API_KEY
  SERVICE_VCL_FRONTEND_DOMAIN_NAME = each.value.frontend_domain
  SERVICE_VCL_BACKEND_HOSTNAME     = each.value.backend_hostname
  NGWAF_SITE                       = var.NGWAF_SITE
  providers = {
    sigsci = sigsci
    fastly = fastly
  }
}


output "live_waf_love" {
  value = module.service_vcl
}
