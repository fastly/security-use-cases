provider "sigsci" {
  corp       = var.NGWAF_CORP
  email      = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
}

provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

module "service_vcl" {
  source                           = "../modules/service-vcl"
  FASTLY_API_KEY                   = var.FASTLY_API_KEY
  SERVICE_VCL_FRONTEND_DOMAIN_NAME = var.SERVICE_VCL_FRONTEND_DOMAIN_NAME
  SERVICE_VCL_BACKEND_HOSTNAME     = var.SERVICE_VCL_BACKEND_HOSTNAME
  NGWAF_SITE                       = var.NGWAF_SITE

  providers = {
    fastly = fastly
    sigsci = sigsci
  }
}
