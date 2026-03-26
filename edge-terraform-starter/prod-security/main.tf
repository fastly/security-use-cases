# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices

#### Supply NGWAF API authentication - Start
# environment variables must be available using "TF_VAR_*" in your terminal. 
# For example, `echo $TF_VAR_NGWAF_CORP` should return your intended corp.
provider "sigsci" {
  corp       = var.NGWAF_CORP
  email      = var.NGWAF_EMAIL
  auth_token = var.NGWAF_TOKEN
}
#### Supply NGWAF API authentication - End

module "edge_security" {
  source                           = "../modules/edge-security"
  NGWAF_EMAIL                      = var.NGWAF_EMAIL
  NGWAF_TOKEN                      = var.NGWAF_TOKEN
  NGWAF_CORP                       = var.NGWAF_CORP
  NGWAF_SITE                       = var.NGWAF_SITE
}

#### Rate Limiting Enumeration Attempts - Start
resource "sigsci_site_signal_tag" "bad-response-signal" {
  site_short_name = var.NGWAF_SITE
  name            = "bad-response"
  description     = "Identification of attacks from malicious IPs"
  depends_on = [ module.edge_security ]
}

resource "sigsci_site_rule" "enumeration-attack-rule" {
  site_short_name = var.NGWAF_SITE
  type            = "rateLimit"
  group_operator  = "any"
  enabled         = true
  reason          = "Blocking IPs that have too many bad responses. Likely an enumeration attack."
  expiration      = ""

  conditions {
    type     = "single"
    field    = "responseCode"
    operator = "like"
    value    = "4[0-9][0-9]"
  }
  conditions {
    type     = "single"
    field    = "responseCode"
    operator = "like"
    value    = "5[0-9][0-9]"
  }
  # actions {
  #   type          = "blockSignal"
  #   signal        = "ALL-REQUESTS"
  #   response_code = 406
  # }

  actions {
    type   = "logRequest"
    signal = sigsci_site_signal_tag.bad-response-signal.id
  }

  rate_limit = {
    threshold = 10,
    interval  = 1,
    duration  = 600,
    # clientIdentifiers = "ip" Defaults to IP
  }
  signal = sigsci_site_signal_tag.bad-response-signal.id

  depends_on = [
    sigsci_site_signal_tag.bad-response-signal,
    module.edge_security
  ]
}

#### Rate Limiting Enumeration Attempts - End


output "live_waf_love_output" {
  value = <<tfmultiline

  #### Click the URL to go to the Fastly NGWAF service ####
  https://dashboard.signalsciences.net/corps/${var.NGWAF_CORP}/sites/${var.NGWAF_SITE}

  tfmultiline
  
}