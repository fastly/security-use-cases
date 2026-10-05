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

#### NGWAF Workspace - Start
variable "NGWAF_WORKSPACE_NAME" {
  type        = string
  description = "Display name for the Next-Gen WAF workspace."
}

variable "NGWAF_MODE" {
  type        = string
  description = "Workspace operation mode: off, log, or block."
  default     = "log"
}
#### NGWAF Workspace - End
