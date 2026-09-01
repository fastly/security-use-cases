#### Add rules from https://www.fastly.com/blog/stronger-security-with-a-unified-cdn-and-waf

# Using JA3 signatures and ASNs
resource "fastly_ngwaf_account_list" "malicious-ja3s-list" {
  name = "malicious-ja3s-list"
  type = "string"
  entries = [
    "entries_go_here",
  ]
}
resource "fastly_ngwaf_account_signal" "malicious-ja3-signal" {
  name        = "malicious-ja3"
  description = "corp level malicious ja3"
  applies_to  = ["*"]
}

resource "fastly_ngwaf_account_rule" "malicious-ja3-rule" {
  applies_to      = ["*"]
  type            = "request"
  description     = "malicious-ja3-rule"
  enabled         = true
  group_operator  = "all"
  request_logging = "sampled"

  multival_condition {
    field          = "request_header"
    group_operator = "all"
    operator       = "exists"
    condition {
      field    = "name"
      operator = "equals"
      value    = "client-ja3"
    }

    condition {
      field    = "value_string"
      operator = "in_list"
      value    = "corp.${fastly_ngwaf_account_list.malicious-ja3s-list.name}"
    }
  }
  action {
    type   = "add_signal"
    signal = "corp.${fastly_ngwaf_account_signal.malicious-ja3-signal.name}"
  }
}

# Utilizing the ASN header
resource "fastly_ngwaf_account_list" "bad-reputation-asn-list" {
  name = "bad-reputation-asn-list"
  type = "string"
  entries = [
    "entries_go_here",
  ]
}
resource "fastly_ngwaf_account_signal" "bad-reputation-asn-signal" {
  name        = "bad-reputation-asn"
  description = "corp level bad reputation asn"
  applies_to  = ["*"]
}

resource "fastly_ngwaf_account_rule" "bad-reputation-asn-rule" {
  applies_to      = ["*"]
  type            = "request"
  description     = "bad-reputation-asn"
  enabled         = true
  group_operator  = "all"
  request_logging = "sampled"

  multival_condition {
    field          = "request_header"
    group_operator = "all"
    operator       = "exists"
    condition {
      field    = "name"
      operator = "equals"
      value    = "asn"
    }
    condition {
      field    = "value_string"
      operator = "in_list"
      value    = "corp.${fastly_ngwaf_account_list.bad-reputation-asn-list.name}"
    }
  }
  action {
    type   = "add_signal"
    signal = "corp.${fastly_ngwaf_account_signal.bad-reputation-asn-signal.name}"
  }
}

# Taking Advantage of the Proxy Headers
resource "fastly_ngwaf_account_signal" "suspicious-hosting-signal" {
  name        = "suspicious-hosting"
  description = "suspicious hosting provider"
  applies_to  = ["*"]
}

resource "fastly_ngwaf_account_rule" "suspicious-hosting-rule" {
  applies_to      = ["*"]
  type            = "request"
  description     = "suspicious-hosting"
  enabled         = true
  group_operator  = "all"
  request_logging = "sampled"

  multival_condition {
    field          = "request_header"
    group_operator = "all"
    operator       = "exists"
    condition {
      field    = "name"
      operator = "equals"
      value    = "proxy-type"
    }
    condition {
      field    = "value_string"
      operator = "equals"
      value    = "hosting"
    }
  }
  multival_condition {
    field          = "request_header"
    group_operator = "all"
    operator       = "exists"
    condition {
      field    = "name"
      operator = "equals"
      value    = "proxy-desc"
    }
    condition {
      field    = "value_string"
      operator = "does_not_equal"
      value    = "cloud"
    }
  }
  action {
    type   = "add_signal"
    signal = "corp.${fastly_ngwaf_account_signal.suspicious-hosting-signal.name}"
  }
}

# Optimize NGWAF enforcement with the Edge Cloud Network
# Rate limiting rule
