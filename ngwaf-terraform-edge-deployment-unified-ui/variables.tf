# Fastly Edge VCL configuration
variable "FASTLY_API_KEY" {
    type        = string
    description = "This is API key for the Fastly configuration."
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
  default       = "http.edgecompute.app"
}


#### VCL Service variables - End

#### NGWAF variables - Start

variable "NGWAF_WORKSPACE_NAME" {
  type          = string
  description   = "Workspace ID for NGWAF"
}

#### NGWAF variables - End

