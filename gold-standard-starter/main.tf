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

# resource "sigsci_site" "tenant_site" {
#   short_name = var.NGWAF_SITE
#   display_name = var.NGWAF_SITE
#   block_duration_seconds = 86400
#   agent_anon_mode = ""
#   agent_level = "log"
# }

#### Block Any Attack Signal from Attack Sources - Start
resource "sigsci_corp_list" "system-attack-signals-list" {
  name = "system-attack-signals"
  type = "signal"
  entries = [
    "BACKDOOR",
    "CMDEXE",
    "SQLI",
    "TRAVERSAL",
    "USERAGENT",
    "XSS",
    "LOG4J-JNDI",
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
  short_name  = "malicious-attacker"
  description = "Identification of attacks from attacking IPs"
}

resource "sigsci_corp_rule" "malicious-attacker-rule" {
  site_short_names = []
  type             = "request"
  corp_scope       = "global"
  group_operator   = "all"
  enabled          = true
  reason           = "Detect attacks from known attacking IPs"
  expiration       = ""


  conditions {
    type           = "multival"
    field          = "signal"
    group_operator = "all"
    operator       = "exists"

    conditions {
      type     = "single"
      field    = "signalType"
      operator = "inList"
      value    = sigsci_corp_list.system-attack-signals-list.id
    }
    conditions {
      type     = "single"
      field    = "signalType"
      operator = "inList"
      value    = sigsci_corp_list.attack-sources-signals-list.id
    }
  }
  # Easily go into blocking by uncommenting the following action
  # actions {
  #   type = "block"
  # }
  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.malicious-attacker-signal.id
  }

  depends_on = [
    sigsci_corp_list.system-attack-signals-list,
    sigsci_corp_list.attack-sources-signals-list,
  ]
}
#### Block Any Attack Signal from Attack Sources - End



#### Block Requests from Countries that are not revenue generating - Start
# Also consider, https://home.treasury.gov/policy-issues/office-of-foreign-assets-control-sanctions-programs-and-information
resource "sigsci_corp_signal_tag" "blocked-countries-corp-signal" {
  short_name  = "blocked-countries"
  description = "Block countries that are not revenue generating"
}

resource "sigsci_corp_list" "blocked-countries-corp-list" {
  name = "blocked-countries"
  type = "country"
  entries = [
    "KP",
  ]
  description = "Block countries that are not revenue generating. KP is North Korea."
}

resource "sigsci_corp_rule" "blocked-countries-corp-rule" {
  site_short_names = []
  type             = "request"
  corp_scope       = "global"
  enabled          = true
  group_operator   = "all"
  reason           = "Country Blocking Rule"
  expiration       = ""

  conditions {
    type     = "single"
    field    = "country"
    operator = "inList"
    value    = sigsci_corp_list.blocked-countries-corp-list.id
  }

  # Easily go into blocking by uncommenting the following action
  # actions {
  #   type = "block"
  # }

  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.blocked-countries-corp-signal.id
  }

  depends_on = [
    sigsci_corp_list.blocked-countries-corp-list,
    sigsci_corp_signal_tag.blocked-countries-corp-signal,
  ]
}
#### Block Requests from Countries that are not revenue generating - End



#### Lower Attack Thresholds - Start
resource "sigsci_corp_signal_tag" "system-attack-signal" {
  short_name  = "system-attack"
  description = "Tagging requests with that match any attack"
}

resource "sigsci_corp_rule" "system-attack-rule" {
  site_short_names = []
  type             = "request"
  corp_scope       = "global"
  group_operator   = "all"
  enabled          = true
  reason           = "Add a signal for any attack"
  expiration       = ""

  conditions {
    type           = "multival"
    field          = "signal"
    group_operator = "all"
    operator       = "exists"

    conditions {
      type     = "single"
      field    = "signalType"
      operator = "inList"
      value    = sigsci_corp_list.system-attack-signals-list.id
    }
  }
  #### Easily go into blocking by uncommenting the following action
  # actions {
  #   type = "block"
  # }
  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.system-attack-signal.id
  }
  depends_on = [
    sigsci_corp_list.system-attack-signals-list,
    sigsci_corp_signal_tag.system-attack-signal,
  ]
}

# Lower the thresholds for any system attack - Start
# Docs. https://registry.terraform.io/providers/signalsciences/sigsci/latest/docs/resources/site_alert
resource "sigsci_site_alert" "any-attack-site-alert-1min" {
  site_short_name    = var.NGWAF_SITE
  tag_name           = sigsci_corp_signal_tag.system-attack-signal.id
  long_name          = "Any system attack alert 1 min"
  interval           = 1
  threshold          = 50
  enabled            = true
  action             = "info"
  skip_notifications = true

  depends_on = [
    sigsci_corp_signal_tag.system-attack-signal,
  ]
}

resource "sigsci_site_alert" "any-attack-site-alert-10min" {
  site_short_name    = var.NGWAF_SITE
  tag_name           = sigsci_corp_signal_tag.system-attack-signal.id
  long_name          = "Any system attack alert 10 min"
  interval           = 10
  threshold          = 350
  enabled            = true
  action             = "info"
  skip_notifications = true

  depends_on = [
    sigsci_corp_signal_tag.system-attack-signal
  ]
}

resource "sigsci_site_alert" "any-attack-site-alert-60min" {
  site_short_name    = var.NGWAF_SITE
  tag_name           = sigsci_corp_signal_tag.system-attack-signal.id
  long_name          = "Any system attack alert 60 min"
  interval           = 60
  threshold          = 1800
  enabled            = true
  action             = "info"
  skip_notifications = true

  depends_on = [
    sigsci_corp_signal_tag.system-attack-signal
  ]
}
#### Lower Attack Thresholds - End

#### Anomoly Signals - Start
resource "sigsci_corp_signal_tag" "anomaly-attack-signal" {
  short_name  = "anomaly-attack"
  description = "Identification of attacks from Anomaly traffic"
}

resource "sigsci_corp_list" "anomaly-attack-signals-list" {
  name = "anomaly-attack-signals"
  type = "signal"
  entries = [
    "ABNORMALPATH",
    "CODEINJECTION",
    "DOUBLEENCODING",
    "DUPLICATE-HEADERS",
    "NOTUTF8",
    "MALFORMED-DATA",
    "NOUA",
    "PRIVATEFILE",
    "RESPONSESPLIT",
  ]
}

resource "sigsci_corp_rule" "anomaly-attack-corp-rule" {
  site_short_names = []
  type             = "request"
  corp_scope       = "global"
  group_operator   = "all"
  enabled          = true
  reason           = "Identify attacks from Anomaly Traffic"
  expiration       = ""
  conditions {
    type           = "multival"
    field          = "signal"
    group_operator = "all"
    operator       = "exists"

    conditions {
      type     = "single"
      field    = "signalType"
      operator = "inList"
      value    = sigsci_corp_list.anomaly-attack-signals-list.id
    }
  }
  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.anomaly-attack-signal.id
  }
  #### Easily go into blocking by uncommenting the following action
  # actions {
  #   type = "block"
  # }
  depends_on = [
    sigsci_corp_list.anomaly-attack-signals-list,
    sigsci_corp_signal_tag.anomaly-attack-signal,
  ]
}
#### Anomoly Signals - End

#### Rate Limiting Enumeration Attempts - Start
resource "sigsci_site_signal_tag" "bad-response-signal" {
  site_short_name = var.NGWAF_SITE
  name            = "bad-response"
  description     = "Identification of attacks from malicious IPs"

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

  rate_limit {
    threshold = 10
    interval  = 1
    duration  = 600
    client_identifiers {
      type = "ip" # Defaults to IP
    }
  }

  signal = sigsci_site_signal_tag.bad-response-signal.id

  depends_on = [
    sigsci_site_signal_tag.bad-response-signal,
  ]
}

#### Rate Limiting Enumeration Attempts - End


output "live_waf_love_output" {
  value = <<tfmultiline

  #### Click the URL to go to the Fastly NGWAF service ####
  https://dashboard.signalsciences.net/corps/${var.NGWAF_CORP}/sites/${var.NGWAF_SITE}

  tfmultiline

}
