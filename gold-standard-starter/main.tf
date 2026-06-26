# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices

#### Supply NGWAF API authentication - Start
# environment variables must be available using "TF_VAR_*" in your terminal.
# For example, `echo $TF_VAR_NGWAF_WORKSPACE` should return your intended corp.
provider "fastly" {
  # Authenticates via FASTLY_API_KEY environment variable.
  # The NGWAF resources use the same API key as all other Fastly resources.
}
#### Supply NGWAF API authentication - End

#### NGWAF Workspace - Start
resource "fastly_ngwaf_workspace" "tenant_workspace" {
  name        = var.NGWAF_WORKSPACE
  description = "Fastly Gold Standard Starter"
  mode        = "log"

  attack_signal_thresholds {
    one_minute  = 50
    ten_minutes = 350
    one_hour    = 1800
    immediate   = false
  }
}
#### NGWAF Workspace - End

#### Block Any Attack Signal from Attack Sources - Start
resource "fastly_ngwaf_account_list" "system-attack-signals-list" {
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

resource "fastly_ngwaf_account_list" "attack-sources-signals-list" {
  name = "attack-sources-signals"
  type = "signal"
  entries = [
    "SIGSCI-IP",
    "SANS",
    "TORNODE",
  ]
}

resource "fastly_ngwaf_account_signal" "malicious-attacker-signal" {
  name        = "malicious-attacker"
  description = "Identification of attacks from attacking IPs"
  applies_to  = ["*"]
}

resource "fastly_ngwaf_account_rule" "malicious-attacker-rule" {
  applies_to      = ["*"]
  type            = "request"
  description     = "Detect attacks from known attacking IPs"
  enabled         = true
  group_operator  = "all"
  request_logging = "sampled"

  multival_condition {
    field          = "signal"
    group_operator = "all"
    operator       = "exists"

    condition {
      field    = "signal_id"
      operator = "in_list"
      value    = "corp.${fastly_ngwaf_account_list.system-attack-signals-list.name}"
    }
    condition {
      field    = "signal_id"
      operator = "in_list"
      value    = "corp.${fastly_ngwaf_account_list.attack-sources-signals-list.name}"
    }
  }
  # Easily go into blocking by uncommenting the following action
  # action {
  #   type = "block"
  # }
  action {
    type   = "add_signal"
    signal = "corp.${fastly_ngwaf_account_signal.malicious-attacker-signal.name}"
  }

  depends_on = [
    fastly_ngwaf_account_list.system-attack-signals-list,
    fastly_ngwaf_account_list.attack-sources-signals-list,
  ]
}
#### Block Any Attack Signal from Attack Sources - End



#### Block Requests from Countries that are not revenue generating - Start
# Also consider, https://home.treasury.gov/policy-issues/office-of-foreign-assets-control-sanctions-programs-and-information
resource "fastly_ngwaf_account_signal" "blocked-countries-corp-signal" {
  name        = "blocked-countries"
  description = "Block countries that are not revenue generating"
  applies_to  = ["*"]
}

resource "fastly_ngwaf_account_list" "blocked-countries-corp-list" {
  name = "blocked-countries"
  type = "country"
  entries = [
    "KP",
  ]
  description = "Block countries that are not revenue generating. KP is North Korea."
}

resource "fastly_ngwaf_account_rule" "blocked-countries-corp-rule" {
  applies_to      = ["*"]
  type            = "request"
  description     = "Country Blocking Rule"
  enabled         = true
  group_operator  = "all"
  request_logging = "sampled"

  condition {
    field    = "country"
    operator = "in_list"
    value    = "corp.${fastly_ngwaf_account_list.blocked-countries-corp-list.name}"
  }

  # Easily go into blocking by uncommenting the following action
  # action {
  #   type = "block"
  # }

  action {
    type   = "add_signal"
    signal = "corp.${fastly_ngwaf_account_signal.blocked-countries-corp-signal.name}"
  }

  depends_on = [
    fastly_ngwaf_account_list.blocked-countries-corp-list,
    fastly_ngwaf_account_signal.blocked-countries-corp-signal,
  ]
}
#### Block Requests from Countries that are not revenue generating - End



#### Lower Attack Thresholds - Start
resource "fastly_ngwaf_account_signal" "system-attack-signal" {
  name        = "system-attack"
  description = "Tagging requests with that match any attack"
  applies_to  = ["*"]
}

resource "fastly_ngwaf_account_rule" "system-attack-rule" {
  applies_to      = ["*"]
  type            = "request"
  description     = "Add a signal for any attack"
  enabled         = true
  group_operator  = "all"
  request_logging = "sampled"

  multival_condition {
    field          = "signal"
    group_operator = "all"
    operator       = "exists"

    condition {
      field    = "signal_id"
      operator = "in_list"
      value    = "corp.${fastly_ngwaf_account_list.system-attack-signals-list.name}"
    }
  }
  #### Easily go into blocking by uncommenting the following action
  # action {
  #   type = "block"
  # }
  action {
    type   = "add_signal"
    signal = "corp.${fastly_ngwaf_account_signal.system-attack-signal.name}"
  }
  depends_on = [
    fastly_ngwaf_account_list.system-attack-signals-list,
    fastly_ngwaf_account_signal.system-attack-signal,
  ]
}

#### Anomaly Signals - Start
resource "fastly_ngwaf_account_signal" "anomaly-attack-signal" {
  name        = "anomaly-attack"
  description = "Identification of attacks from Anomaly traffic"
  applies_to  = ["*"]
}

resource "fastly_ngwaf_account_list" "anomaly-attack-signals-list" {
  name = "anomaly-attack-signals"
  type = "signal"
  entries = [
    "ABNORMALPATH",
    "CODEINJECTION",
    "DOUBLEENCODING",
    "NOTUTF8",
    "MALFORMED-DATA",
    "NOUA",
    "PRIVATEFILE",
    "RESPONSESPLIT",
  ]
}

resource "fastly_ngwaf_account_rule" "anomaly-attack-corp-rule" {
  applies_to      = ["*"]
  type            = "request"
  description     = "Identify attacks from Anomaly Traffic"
  enabled         = true
  group_operator  = "all"
  request_logging = "sampled"

  multival_condition {
    field          = "signal"
    group_operator = "all"
    operator       = "exists"

    condition {
      field    = "signal_id"
      operator = "in_list"
      value    = "corp.${fastly_ngwaf_account_list.anomaly-attack-signals-list.name}"
    }
  }
  action {
    type   = "add_signal"
    signal = "corp.${fastly_ngwaf_account_signal.anomaly-attack-signal.name}"
  }
  #### Easily go into blocking by uncommenting the following action
  # action {
  #   type = "block"
  # }
  depends_on = [
    fastly_ngwaf_account_list.anomaly-attack-signals-list,
    fastly_ngwaf_account_signal.anomaly-attack-signal,
  ]
}
#### Anomaly Signals - End

#### Rate Limiting Enumeration Attempts - Start
resource "fastly_ngwaf_workspace_signal" "bad-response-signal" {
  workspace_id = fastly_ngwaf_workspace.tenant_workspace.id
  name         = "bad-response"
  description  = "Identification of attacks from malicious IPs"
}

resource "fastly_ngwaf_workspace_rule" "enumeration-attack-rule" {
  workspace_id   = fastly_ngwaf_workspace.tenant_workspace.id
  type           = "rate_limit"
  group_operator = "any"
  enabled        = true
  description    = "Blocking IPs that have too many bad responses. Likely an enumeration attack."

  condition {
    field    = "response_code"
    operator = "like"
    value    = "4[0-9][0-9]"
  }
  condition {
    field    = "response_code"
    operator = "like"
    value    = "5[0-9][0-9]"
  }
  # action {
  #   type          = "block_signal"
  #   signal        = "ALL-REQUESTS"
  #   response_code = 406
  # }

  action {
    type   = "log_request"
    signal = "site.${fastly_ngwaf_workspace_signal.bad-response-signal.name}"
  }

  rate_limit {
    threshold = 10
    interval  = 60
    duration  = 600
    signal    = "site.${fastly_ngwaf_workspace_signal.bad-response-signal.name}"
    client_identifiers {
      type = "ip"
    }
  }

  depends_on = [
    fastly_ngwaf_workspace_signal.bad-response-signal,
  ]
}

#### Rate Limiting Enumeration Attempts - End


output "live_waf_love_output" {
  value = <<tfmultiline

  #### Click the URL to go to the Fastly NGWAF workspace ####
  https://manage.fastly.com/security/ngwaf/workspaces/${fastly_ngwaf_workspace.tenant_workspace.id}/dashboards

  tfmultiline

}
