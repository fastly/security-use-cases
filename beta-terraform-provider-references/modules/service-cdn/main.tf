# The provider that configures `fastly` is supplied by the caller
# (dev-delivery / prod-delivery), so no `provider "fastly" {}` block appears
# here.

resource "fastly_service_cdn_auto" "this" {
  name    = var.SERVICE_NAME
  comment = "Managed by Terraform"

  backend {
    name              = "origin"
    address           = var.BACKEND_ADDRESS
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = var.BACKEND_ADDRESS
    ssl_sni_hostname  = var.BACKEND_ADDRESS
    override_host     = var.BACKEND_ADDRESS
  }

  snippet {
    name     = "cdn_enrichment"
    type     = "recv"
    priority = 110
    content  = file("${path.module}/vcl/cdn_enrichment.vcl")
  }

  snippet {
    name     = "disable_caching"
    type     = "recv"
    priority = 9000
    content  = file("${path.module}/vcl/disable_caching.vcl")
  }

  force_destroy = true
}

# Each product is its own resource: creating it enables the product on
# service_id, destroying it disables it. Only created when a workspace ID is
# supplied, so this module works with or without Next-Gen WAF enabled.
resource "fastly_service_product_ngwaf" "this" {
  count = var.NGWAF_WORKSPACE_ID == null ? 0 : 1

  service_id   = fastly_service_cdn_auto.this.id
  workspace_id = var.NGWAF_WORKSPACE_ID
}

output "service_id" {
  description = "The Fastly service ID."
  value       = fastly_service_cdn_auto.this.id
}

output "active_version" {
  description = "The currently active service version."
  value       = fastly_service_cdn_auto.this.active_version
}

output "managed_version" {
  description = "The latest service version selected and managed by this resource."
  value       = fastly_service_cdn_auto.this.managed_version
}

output "service_hints" {
  description = "Hints on what to do next."
  value       = <<-EOT
    View this service in the Fastly control panel:
      https://manage.fastly.com/configure/services/${fastly_service_cdn_auto.this.id}

    Check it's serving traffic:
      curl -v https://${fastly_service_cdn_auto.this.id}.global.ssl.fastly.net/

    Confirm the JA3/ASN enrichment snippet is running by inspecting the
    request headers your origin receives (Client-JA3, asn, proxy-type,
    proxy-desc).
  EOT
}
