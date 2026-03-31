variable "fastly_routes" {
  description = "A list of objects representing the domain and corresponding origin names."
  type = list(object({
    domain_name = string
    origin_name = string
  }))
  default = []
}

variable "add_header_based_on_path" {
  description = "A list of objects representing path-based header additions. If the request matches the path, the specified header is added."
  type = list(object({
    path         = string
    header_name  = string
    header_value = string
  }))
  default = []
}