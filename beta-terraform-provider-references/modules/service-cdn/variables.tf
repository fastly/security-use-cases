#### Service - Start
variable "SERVICE_NAME" {
  type        = string
  description = "Name of the Fastly CDN service."
}

variable "BACKEND_ADDRESS" {
  type        = string
  description = "Hostname of the origin backend. This value is used for TLS/SNI and Host header semantics, so it must be a DNS name rather than an IP address."
  default     = "http-me.edgecompute.app"
}
#### Service - End

#### Next-Gen WAF - Start
variable "NGWAF_WORKSPACE_ID" {
  type        = string
  description = "ID of a fastly_ngwaf_workspace to link to this service. Leave null to skip enabling Next-Gen WAF."
  default     = null
}
#### Next-Gen WAF - End
