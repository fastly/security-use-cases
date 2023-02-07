# Try to follow best practices here, https://www.terraform-best-practices.com/code-structure

#### Supply NGWAF API authentication - Start
# environment variables must be available using "TF_VAR_*" in your terminal. 
# For example, `echo $TF_VAR_NGWAF_CORP` should return your intended corp.
provider "sigsci" {
  corp = "${var.NGWAF_CORP}"
  email = "${var.NGWAF_EMAIL}"
  auth_token = "${var.NGWAF_TOKEN}"
}
#### Supply NGWAF API authentication - End

#### Block Any Attack Signal from Attack Sources - Start
resource "sigsci_corp_list" "any-attack-signal-list" {
    name = "any-attack-signal"
    type = "signal"
    entries = [
      "BACKDOOR",
      "CMDEXE",
      "SQLI",
      "TRAVERSAL",
      "USERAGENT",
      "XSS",
    ]
}

resource "sigsci_corp_list" "attack-sources-signals-list" {
    name = "attack-sources-signals"
    type = "signal"
    entries = [
      "SIGSCI-IP",
      "SANS",
      "TORNODE",
    ]
}

resource "sigsci_corp_signal_tag" "malicious-attacker-signal" {
  short_name  = "corp.malicious-attacker"
  description = "Identification of attacks from malicious IPs"
}

resource "sigsci_corp_rule" "malicious-attacker-rule" {
  site_short_names = []
  type            = "request"
  corp_scope      = "global"
  group_operator  = "all"
  enabled         = true
  reason          = "Blocking attacks from known Malicious IPs"
  expiration      = ""


  conditions {
    type     = "multival"
    field    = "signal"
    group_operator = "all"
    operator = "exists"

    conditions {
      type     = "single"
      field    = "signalType"
      operator = "inList"
      value = "corp.any-attack-signal"
    }
    conditions {
      type     = "single"
      field    = "signalType"
      operator = "inList"
      value = "corp.attack-sources-signals"
    }
  }
  actions {
    type = "block"
  }
    actions {
    type = "addSignal"
    signal = "corp.malicious-attacker" 
  }
}
#### Block Any Attack Signal from Attack Sources - End

#### 404 Rate Limit Rule - Start
resource "sigsci_site_signal_tag" "bad-response-signal" {
  site_short_name  = var.NGWAF_SITE
  name            = "bad-response"
  description = "Identification of attacks from malicious IPs"
}

resource "sigsci_site_rule" "malicious-attacker-rule" {
  site_short_name = "test"
  type            = "rateLimit"
  group_operator  = "all"
  enabled         = true
  reason          = "Blocking IPs that have too many bad responses"
  expiration      = ""

  conditions {
    type     = "single"
    field    = "responseCode"
    operator = "equals"
    value = "404"
  }
  actions {
    type = "blockSignal"
    signal = "ALL-REQUESTS"
    response_code = 406
  }

  rate_limit = {
    threshold = 5,
    interval =  1,
    duration  = 600,
    clientIdentifiers = "ip"
  }
  signal = "site.bad-response"
}

#### 404 Rate Limit Rule - End

#### Block Requests from Countries on the OFAC List - Start
# https://home.treasury.gov/policy-issues/office-of-foreign-assets-control-sanctions-programs-and-information
resource "sigsci_corp_signal_tag" "ofac" {
  short_name  = "ofac"
  description = "Countries on OFAC list"
}

resource "sigsci_corp_list" "ofac-countries-corp-list" {
    name = "OFAC-Countries"
    type = "country"
    entries = [
        "IR",
        "SY",
        "SD",
        "KP",
        "BY",
        "CI",
        "CU",
        "CD",
        "IQ",
        "LR",
        "MM",
        "ZW",
    ]
}

resource "sigsci_corp_rule" "ofac-rule" {
  site_short_names = []
  type = "request"
  corp_scope = "global"
  enabled = true
  group_operator = "all"
  reason = "OFAC Country Blocking Rule"
  expiration = ""

  conditions {
    type     = "single"
    field    = "country"
    operator = "inList"
    value = "corp.ofac-countries"
  }

  actions {
    type = "block"
  }

  actions {
    type = "addSignal"
    signal = "corp.ofac" 
  }

  depends_on = [
  sigsci_corp_list.ofac-countries-corp-list
  ]
}
#### Block Requests from Countries on the OFAC List - End

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
    value = "corp.bad-ua"
  }

  actions {
    type = "block"
  }

  actions {
    type = "addSignal"
    signal = "corp.bad-ua" 
  }
}
#### Block Requests from Known Bad User Agents - Start


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
    value = "corp.domain-list"
  }

  actions {
    type   = "addSignal"
    signal = "corp.missing-domain-request" 
  }
  depends_on = [
  sigsci_corp_list.domain-list
  ]
}
#### Block Requests with Invalid Host Header - End
