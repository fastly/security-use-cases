variable "fastly_routes" {
  description = "A list of objects representing the domain and corresponding origin names."
  type = list(object({
    domain_name = string
    origin_name = string
  }))
  default = []
}