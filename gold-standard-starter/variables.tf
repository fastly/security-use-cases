# variables for the initial provider setup
variable "NGWAF_CORP" {
    type        = string
    description = "This is the corp where configuration changes will be made."
}
variable "NGWAF_EMAIL" {
    type        = string
    description = "This is the email address associated with the token for the NGWAF API."
}
variable "NGWAF_TOKEN" {
    type        = string
    description = "This is a secret token for the NGWAF API."
    sensitive   = true
}
variable "NGWAF_SITE" {
    type        = string
    description = "This is the site for the NGWAF."
}

