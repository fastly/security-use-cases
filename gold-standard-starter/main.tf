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

#### Any Attack Signal - Start
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
#### Any Attack Signal - End

#### Any Attack Source - Start
resource "sigsci_corp_list" "attack-sources-signals-list" {
    name = "attack-sources-signals"
    type = "signal"
    entries = [
      "SIGSCI-IP",
      "SANS",
      "TORNODE",
    ]
}
#### Any Attack Source - End

#### Malicious Attacker Rule - Start
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
#### Malicious Attacker Rule - End

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