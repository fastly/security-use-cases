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

# A faithful analog of edge-terraform-starter's "enumeration-attack-rule":
# flag clients generating an abnormal share of 4xx/5xx responses. Logged only
# by default; swap the action to block_signal (and NGWAF_MODE to "block") to
# enforce.
resource "fastly_ngwaf_workspace_rate_limit_rule" "high_error_rate" {
  workspace_id = fastly_ngwaf_workspace.this.id
  description  = "Rate limit clients generating excessive 4xx/5xx responses"
  enabled      = true

  condition {
    field    = "response_code"
    operator = "greater_equal"
    value    = "400"
  }

  rate_limit {
    signal    = "site.high-error-rate"
    threshold = 10
    interval  = 60
    duration  = 600

    client_identifiers {
      type = "ip"
    }
  }

  action {
    type   = "log_request"
    signal = "site.high-error-rate"
  }
}

output "ngwaf_workspace_id" {
  description = "The Next-Gen WAF workspace ID. Copy this into the matching *-delivery environment's NGWAF_WORKSPACE_ID variable to link a CDN service to this workspace."
  value       = fastly_ngwaf_workspace.this.id
}
