# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices

#### Supply NGWAF API authentication - Start
# environment variables must be available using "TF_VAR_*" in your terminal. 
# For example, `echo $TF_VAR_NGWAF_CORP` should return your intended corp.
# provider "sigsci" {
#   corp       = var.NGWAF_CORP
#   email      = var.NGWAF_EMAIL
#   auth_token = var.NGWAF_TOKEN
# }
#### Supply NGWAF API authentication - End

resource "sigsci_site" "ngwaf_workspace_site" {
  short_name = var.NGWAF_SITE
  display_name = var.NGWAF_SITE
  block_duration_seconds = 86400
  agent_anon_mode = ""
  agent_level = "log"
}

resource "sigsci_edge_deployment" "ngwaf_edge_site_service" {
  # https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/edge_deployment
  site_short_name = sigsci_site.ngwaf_workspace_site.short_name

  # depends_on = [sigsci_site.ngwaf_workspace_site]
}
