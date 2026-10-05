provider "fastly" {
  api_token = var.FASTLY_API_TOKEN
}

# Add or remove a domain by editing domains.json - every entry in its
# "domains" array gets a fastly_domain attached to this one service below.
locals {
  domains = jsondecode(file("${path.module}/domains.json")).domains
}

module "service_cdn" {
  source = "../modules/service-cdn"

  SERVICE_NAME       = var.SERVICE_NAME
  BACKEND_ADDRESS    = var.BACKEND_ADDRESS
  NGWAF_WORKSPACE_ID = var.NGWAF_WORKSPACE_ID
}

resource "fastly_domain" "this" {
  for_each = { for d in local.domains : d.fqdn => d }

  fqdn        = each.key
  description = try(each.value.comment, null)
  service_id  = module.service_cdn.service_id
}

output "service_id" {
  value = module.service_cdn.service_id
}

output "active_version" {
  value = module.service_cdn.active_version
}

output "domain_ids" {
  description = "Map of fqdn -> Fastly domain UUID for every domain in domains.json."
  value       = { for fqdn, d in fastly_domain.this : fqdn => d.id }
}

output "service_hints" {
  value = module.service_cdn.service_hints
}
