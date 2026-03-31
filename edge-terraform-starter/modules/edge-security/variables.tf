#### NGWAF variables - Start

variable "NGWAF_CORP" {
  type          = string
  description   = "Corp name for NGWAF"
}

variable "NGWAF_SITE" {
  type          = string
  description   = "Site name for NGWAF"
}

variable "NGWAF_EMAIL" {
    type        = string
    description = "Email address associated with the token for the NGWAF API."
}
variable "NGWAF_TOKEN" {
    type        = string
    description = "Secret token for the NGWAF API."
    sensitive   = true
}
#### NGWAF variables - End