#### NGWAF Workspace - Start
variable "NGWAF_WORKSPACE_NAME" {
  type        = string
  description = "Display name for the Next-Gen WAF workspace."
}

variable "NGWAF_MODE" {
  type        = string
  description = "Workspace operation mode: off, log, or block."
  default     = "log"

  validation {
    condition     = contains(["off", "log", "block"], var.NGWAF_MODE)
    error_message = "NGWAF_MODE must be one of: off, log, block."
  }
}
#### NGWAF Workspace - End
