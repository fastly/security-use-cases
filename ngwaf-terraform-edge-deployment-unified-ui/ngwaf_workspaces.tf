# https://registry.terraform.io/providers/fastly/fastly/latest/docs/resources/ngwaf_workspace

resource "fastly_ngwaf_workspace" "my_ngwaf_workspace" {
  client_ip_headers              = []
  default_blocking_response_code = 406
  description                    = var.NGWAF_WORKSPACE_NAME
  ip_anonymization               = null
  mode                           = "log"
  name                           = var.NGWAF_WORKSPACE_NAME
  attack_signal_thresholds {
    immediate   = false
  }
}
