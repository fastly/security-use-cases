# Try to follow best practices here, https://www.terraform-best-practices.com/code-structure

#### Supply NGWAF API authentication - Start
# environment variables must be available using "TF_VAR_*" in your terminal. 
# For example, `echo $TF_VAR_NGWAF_CORP` should return your intended corp.
provider "sigsci" {
  corp = "${var.NGWAF_CORP}"
  email = "${var.NGWAF_EMAIL}"
  auth_token = "${var.NGWAF_TOKEN}"
}


#### 404 Rate Limit Rule - Start
resource "sigsci_site_signal_tag" "bad-response-signal" {
  site_short_name  = var.NGWAF_SITE
  name            = "bad-response"
  description = "Identification of attacks from malicious IPs"
}

resource "sigsci_site_rule" "malicious-attacker-rule" {
  site_short_name = "test"
  type            = "rateLimit"
  group_operator  = "any"
  enabled         = true
  reason          = "Blocking IPs that have too many bad responses"
  expiration      = ""

  conditions {
    type     = "single"
    field    = "responseCode"
    operator = "like"
    value = "4[0-9][0-9]"
  }
  conditions {
    type     = "single"
    field    = "responseCode"
    operator = "like"
    value = "5[0-9][0-9]"
  }
  actions {
    type = "blockSignal"
    signal = "ALL-REQUESTS"
    response_code = 406
  }

  rate_limit = {
    threshold = 10,
    interval =  1,
    duration  = 600,
    # clientIdentifiers = "ip" Defaults to IP
  }
  signal = sigsci_site_signal_tag.bad-response-signal.id

  depends_on = [
    sigsci_site_signal_tag.bad-response-signal
  ]
}

#### 404 Rate Limit Rule - End

#### Block Requests from Known Bad User Agents - Start
resource "sigsci_corp_signal_tag" "bad-ua" {
  short_name  = "bad-ua"
  description = "Known bad User Agents"
}

resource "sigsci_corp_list" "bad-ua" {
    name = "Bad UA"
    type = "wildcard"
    entries = [
        "*[Cc][Uu][Rr][Ll]*",
        "*[Pp][Yy][Tt][Hh][Oo][Nn]*",
        "*[Ww][Pp][Ss][Cc][Aa][Nn]*",
        "*[Nn][Mm][Aa][Pp]*",
        "*[Mm][Aa][Ss][Ss][Cc][Aa][Nn]*",
    ]
}

resource "sigsci_corp_rule" "bad-ua" {
  site_short_names = []
  type = "request"
  corp_scope = "global"
  enabled = true
  group_operator = "all"
  reason = "Bad User Agents Blocking Rule"
  expiration = ""

  conditions {
    type     = "single"
    field    = "useragent"
    operator = "inList"
    value = sigsci_corp_list.bad-ua.id
  }

  actions {
    type = "block"
  }

  actions {
    type = "addSignal"
    signal = sigsci_corp_signal_tag.bad-ua.id
  }
  depends_on = [
    sigsci_corp_list.bad-ua,
    sigsci_corp_signal_tag.bad-ua,
  ]
}
#### Block Requests from Known Bad User Agents - End

#### Block Requests with Invalid Host Header - Start
resource "sigsci_corp_signal_tag" "missing-domain-request-signal" {
  short_name  = "missing-domain-request"
  description = "Tagging requests with missing domain"
}

resource "sigsci_corp_list" "domain-list" {
    name = "Domain List"
    type = "wildcard"
    entries = [ // Change values in this list to reflect your domain
        "example.com",
        "*.example.com", 
    ]
}

resource "sigsci_corp_rule" "domain-rule" {
  site_short_names = []
  type = "request"
  corp_scope = "global"
  enabled = true
  group_operator = "all"
  reason = "Identify requests without valid domain in host header"
  expiration = ""

  conditions {
    type     = "single"
    field    = "domain"
    operator = "notInList"
    value = sigsci_corp_list.domain-list.id
  }

  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.missing-domain-request-signal.id
  }
  depends_on = [
    sigsci_corp_list.domain-list,
    sigsci_corp_signal_tag.missing-domain-request-signal,
  ]
}
#### Block Requests with Invalid Host Header - End