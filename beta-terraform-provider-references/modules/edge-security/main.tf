# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices
#
# This module owns a Next-Gen WAF workspace independently of any Fastly CDN or
# Compute service. The provider that configures `fastly` is supplied by the
# caller (dev-security / prod-security), so no `provider "fastly" {}` block
# appears here.

resource "fastly_ngwaf_workspace" "this" {
  name        = var.NGWAF_WORKSPACE_NAME
  description = "Managed by Terraform"
  mode        = var.NGWAF_MODE

  attack_signal_thresholds {}
}

output "ngwaf_workspace_id" {
  description = "The Next-Gen WAF workspace ID. Copy this into the matching *-delivery environment's NGWAF_WORKSPACE_ID variable to link a CDN service to this workspace."
  value       = fastly_ngwaf_workspace.this.id
}
