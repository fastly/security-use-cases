# Fastly Edge VCL configuration
variable "FASTLY_API_KEY" {
    type        = string
    description = "This is API key for the Fastly VCL edge configuration."
}

#### VCL Service variables - Start
variable "USER_VCL_SERVICE_DOMAIN_NAME" {
  type = string
  description = "Frontend domain for your service."
  default = "ngwaf-tf-demo.global.ssl.fastly.net"
}

variable "USER_VCL_SERVICE_BACKEND_HOSTNAME" {
  type          = string
  description   = "hostname used for backend."
  default       = "http-me.glitch.me"
  # default = "status.demotool.site"
  # default = "return-status.demotool.site"
}

# Controls the percentage of traffic sent to NGWAF
variable "Edge_Security_dictionary" {
  type = string
  default = "Edge_Security"
}

#### VCL Service variables - End

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

#### External Logging - Start
variable "HONEYCOMB_API_KEY" {
  # https://www.honeycomb.io/
    type        = string
    description = "Secret token for the Honeycomb API."
    sensitive   = true
    default = ""
}

# Splunk
variable "SPLUNK_LOGGING_NAME" {
  type = string
  default = "SPLUNK_LOGGING"
}

variable "SPLUNK_LOGGING_TOKEN" {
  type = string
  sensitive = true
  default = ""
}

variable "SPLUNK_LOGGING_URL" {
  type = string
  default = ""
}
#### External Logging - END
