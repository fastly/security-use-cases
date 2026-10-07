#### Provider - Start
# Environment variables must be available using TF_VAR_*, e.g.
#   export TF_VAR_FASTLY_API_TOKEN=$(echo $FASTLY_API_TOKEN)
variable "FASTLY_API_TOKEN" {
  type        = string
  description = "Fastly API token. Can also be supplied via the provider's own FASTLY_API_TOKEN environment variable."
  sensitive   = true
  default     = null
}
#### Provider - End

#### Service - Start
variable "SERVICE_NAME" {
  type        = string
  description = "Name of the Fastly CDN service."
}

variable "BACKEND_ADDRESS" {
  type        = string
  description = "Hostname or IP address of the origin backend."
  default     = "http-me.edgecompute.app"
}
#### Service - End

#### Next-Gen WAF - Start
# Apply dev-security first, then copy its ngwaf_workspace_id output here (or
# into inputs.auto.tfvars) to link this service to that workspace. Leave null
# to stand up the CDN service without Next-Gen WAF.
variable "NGWAF_WORKSPACE_ID" {
  type        = string
  description = "ID of the dev Next-Gen WAF workspace (from dev-security's ngwaf_workspace_id output)."
  default     = null
}
#### Next-Gen WAF - End
