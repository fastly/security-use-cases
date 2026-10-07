# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices

provider "fastly" {
  api_token = var.FASTLY_API_TOKEN
}

module "edge_security" {
  source = "../modules/edge-security"

  NGWAF_WORKSPACE_NAME = var.NGWAF_WORKSPACE_NAME
  NGWAF_MODE           = var.NGWAF_MODE
}

output "ngwaf_workspace_id" {
  description = "Copy this value into dev-delivery/inputs.auto.tfvars as NGWAF_WORKSPACE_ID to link the dev CDN service to this workspace."
  value       = module.edge_security.ngwaf_workspace_id
}

output "live_waf_love_output" {
  description = "Output hints on what to do next."
  value       = <<-EOT
    Next-Gen WAF workspace created: ${module.edge_security.ngwaf_workspace_id}

    View it in the Fastly control panel:
      https://manage.fastly.com/ngwaf/workspaces/${module.edge_security.ngwaf_workspace_id}

    Copy the workspace ID above into dev-delivery/inputs.auto.tfvars
    (NGWAF_WORKSPACE_ID) and apply dev-delivery to link a CDN service to it.
  EOT
}
