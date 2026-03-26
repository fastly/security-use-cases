#### variables for the initial provider setup
variable "NGWAF_CORP" {
    type        = string
    description = "NGWAF Corp where configuration changes will be made."
}
variable "NGWAF_SITE" {
    type        = string
    description = "NGWAF Site where configuration changes will be made."
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

