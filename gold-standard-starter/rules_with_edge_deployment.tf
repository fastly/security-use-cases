# Add rules from https://www.fastly.com/blog/stronger-security-with-a-unified-cdn-and-waf


# Using JA3 signatures and ASNs
resource "sigsci_corp_list" "malicious-ja3s-list" {
  name = "malicious-ja3s-list"
  type = "string"
  entries = [
    "entries_go_here",
  ]
}
resource "sigsci_corp_signal_tag" "malicious-ja3-signal" {
  short_name  = "malicious-ja3"
  description = "corp level malicious ja3"
}

resource "sigsci_corp_rule" "malicious-ja3-rule" {
  site_short_names = []
  type             = "request"
  corp_scope       = "global"
  group_operator   = "all"
  enabled          = true
  reason           = "malicious-ja3-rule"
  expiration       = ""
  conditions {
    type           = "multival"
    field          = "requestHeader"
    group_operator = "all"
    operator       = "exists"
    conditions {
      type     = "single"
      field    = "name"
      operator = "equals"
      value    = "client-ja3"
    }

    conditions {
      type     = "single"
      field    = "valueString"
      operator = "inList"
      value    = sigsci_corp_list.malicious-ja3s-list.id
    }
  }
  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.malicious-ja3-signal.id
  }
}

# Utilizing the ASN header
resource "sigsci_corp_list" "bad-reputation-asn-list" {
  name = "bad-reputation-asn-list"
  type = "string"
  entries = [
    "entries_go_here",
  ]
}
resource "sigsci_corp_signal_tag" "bad-reputation-asn-signal" {
  short_name  = "bad-reputation-asn"
  description = "corp level bad reputation asn"
}

resource "sigsci_corp_rule" "bad-reputation-asn-rule" {
  site_short_names = []
  type             = "request"
  corp_scope       = "global"
  group_operator   = "all"
  enabled          = true
  reason           = "bad-reputation-asn"
  expiration       = ""
  conditions {
    type           = "multival"
    field          = "requestHeader"
    group_operator = "all"
    operator       = "exists"
    conditions {
      type     = "single"
      field    = "name"
      operator = "equals"
      value    = "asn"
    }
    conditions {
      type     = "single"
      field    = "valueString"
      operator = "inList"
      value    = sigsci_corp_list.bad-reputation-asn-list.id
    }
  }
  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.bad-reputation-asn-signal.id
  }
}

# Taking Advantage of the Proxy Headers
resource "sigsci_corp_signal_tag" "suspicious-hosting-signal" {
  short_name  = "suspicious-hosting"
  description = "suspicious hosting provider"
}

resource "sigsci_corp_rule" "suspicious-hosting-rule" {
  site_short_names = []
  type             = "request"
  corp_scope       = "global"
  group_operator   = "all"
  enabled          = true
  reason           = "suspicious-hosting"
  expiration       = ""
  conditions {
    type           = "multival"
    field          = "requestHeader"
    group_operator = "all"
    operator       = "exists"
    conditions {
      type     = "single"
      field    = "name"
      operator = "equals"
      value    = "proxy-type"
    }
    conditions {
      type     = "single"
      field    = "valueString"
      operator = "equals"
      value    = "hosting"
    }
  }
  conditions {
    type           = "multival"
    field          = "requestHeader"
    group_operator = "all"
    operator       = "exists"
    conditions {
      type     = "single"
      field    = "name"
      operator = "equals"
      value    = "proxy-desc"
    }
    conditions {
      type     = "single"
      field    = "valueString"
      operator = "doesNotEqual"
      value    = "cloud"
    }
  }
  actions {
    type   = "addSignal"
    signal = sigsci_corp_signal_tag.suspicious-hosting-signal.id
  }
}

# Optimize NGWAF enforcement with the Edge Cloud Network 
# Rate limiting rule
