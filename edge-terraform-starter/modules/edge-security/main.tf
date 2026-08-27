# Try to follow recommended practices here, https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices

resource "fastly_ngwaf_workspace" "ngwaf_workspace" {
  name                         = var.NGWAF_WORKSPACE_NAME
  description                  = "terraform"
  mode                         = "block"

  attack_signal_thresholds {
    one_minute  = 100
    ten_minutes = 500
    one_hour    = 1000
    immediate   = true
  }
}