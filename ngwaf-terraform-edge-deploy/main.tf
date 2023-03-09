# Configure the Fastly Provider
provider "fastly" {
  api_key = var.FASTLY_API_KEY
}

#### Fastly VCL Service - Start
resource "fastly_service_vcl" "frontend-vcl-service" {
  name = "Frontend VCL Service - NGWAF edge deploy"

  domain {
    name    = var.USER_VCL_SERVICE_DOMAIN_NAME
    comment = "Frontend VCL Service - NGWAF edge deploy"
  }
  backend {
    address = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    name = "vcl_service_origin"
    port    = 443
    use_ssl = true
    ssl_cert_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    ssl_sni_hostname = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
    override_host = var.USER_VCL_SERVICE_BACKEND_HOSTNAME
  }

#   #### Only disable caching for testing. Do not disable caching for production traffic.
#   snippet {
#     name = "Disable caching"
#     content = file("${path.module}/vcl/disable_caching.vcl")
#     type = "recv"
#     priority = 100
#   }

  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - Start
#   dynamicsnippet {
#     name     = "ngwaf_config_init"
#     type     = "init"
#     priority = 0
#   }
#   dynamicsnippet {
#     name     = "ngwaf_config_miss"
#     type     = "init"
#     priority = 150
#   }
#   dynamicsnippet {
#     name     = "ngwaf_config_pass"
#     type     = "init"
#     priority = 150
#   }
  #### NGWAF Dynamic Snippets - MANAGED BY FASTLY - End

  # dictionary {
  #   name       = var.Edge_Security_dictionary
  # }

  lifecycle {
    ignore_changes = [
      dictionary,
      # dynamicsnippet,
      product_enablement,
    ]
  }
}

# resource "fastly_service_dictionary_items" "edge_security_dictionary_items" {
#   for_each = {
#   for d in fastly_service_vcl.frontend-vcl-service.dictionary : d.name => d if d.name == var.Edge_Security_dictionary
#   }
#   service_id = fastly_service_vcl.frontend-vcl-service.id
#   dictionary_id = each.value.dictionary_id

#   items = {
#     Enabled: "100"
#   }
# }

#### $ terraform import fastly_service_dynamic_snippet_content.content xxxxxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxxx
# terraform import fastly_service_dynamic_snippet_content.dynamic_snip_ngwaf_config_init BmK2uM1WoI1cZNbnyj0dC7/L2FCDUkD2OoTlgh9QHxc80 
# resource "fastly_service_dynamic_snippet_content" "dynamic_snip_ngwaf_config_init" {
#   for_each = {
#     for d in fastly_service_vcl.frontend-vcl-service.dynamicsnippet : d.name => d if d.name == "My Dynamic Snippet"
#   }
#   service_id      = fastly_service_vcl.frontend-vcl-service.id
#   snippet_id      = each.value.snippet_id
#   manage_snippets = false
#   content = ""
#   # content         = "if ( req.url ) {\n set req.http.my-snippet-test-header = \"true\";\n}"
# }

#### Edge deploy and sync - Start
resource "null_resource" "create_or_update_ngwaf_edge_deploy" {
  # This only needs to run once for each NGWAF site/workspace
  # triggers = {
  #   always_run = timestamp()
  # }

# https://docs.fastly.com/signalsciences/install-guides/edge/edge-deployment/
# curl -H "x-api-user:$SIGSCI_EMAIL" -H "x-api-token:$SIGSCI_TOKEN" \
# -H "Content-Type: application/json" -X PUT \
# https://dashboard.signalsciences.net/api/v0/corps/{corpName}/sites/{siteName}/edgeDeployment

  provisioner "local-exec" {
    command = "curl -X PUT https://dashboard.signalsciences.net/api/v0/corps/${var.NGWAF_CORP}/sites/${var.NGWAF_SITE}/edgeDeployment -H x-api-user:${var.NGWAF_EMAIL} -H x-api-token:${var.NGWAF_TOKEN} -H Content-Type:application/json"
  }
  
  depends_on = [
    fastly_service_vcl.frontend-vcl-service,
  ]
}

resource "null_resource" "create_or_update_ngwaf_edge_deploy_service" {
  # This resource MUST run every time to resync the VCL service origins with the NGWAF edge deploy origins
  triggers = {
    always_run = timestamp()
  }

# https://docs.fastly.com/signalsciences/install-guides/edge/edge-deployment/#mapping-to-the-fastly-service
# curl -H "x-api-user:${SIGSCI_EMAIL}" -H "x-api-token:${SIGSCI_TOKEN}" \
# -H "Fastly-Key: ${FASTLY_KEY}" -H 'Content-Type: application/json' -X PUT \
# https://dashboard.signalsciences.net/api/v0/corps/{corpName}/sites/{siteName}/edgeDeployment/{fastlySID}

  provisioner "local-exec" {
    command = "curl -X PUT https://dashboard.signalsciences.net/api/v0/corps/${var.NGWAF_CORP}/sites/${var.NGWAF_SITE}/edgeDeployment/${fastly_service_vcl.frontend-vcl-service.id} -H x-api-user:${var.NGWAF_EMAIL} -H x-api-token:${var.NGWAF_TOKEN} -H Fastly-Key:${var.FASTLY_API_KEY} -H Content-Type:application/json"
  }
  
  depends_on = [
    null_resource.create_or_update_ngwaf_edge_deploy,
    fastly_service_vcl.frontend-vcl-service,
  ]
}

#### https://registry.terraform.io/providers/hashicorp/external/latest/docs/data-sources/external
# data "external" "create_or_update_ngwaf_edge_deploy_service" {
#   # triggers = {
#   #   always_run = timestamp()
#   # }

#   # program = ["python", "${path.module}/example-data-source.py"]
#   program = ["/bin/sh", "-c", "curl -X PUT https://dashboard.signalsciences.net/api/v0/corps/${var.NGWAF_CORPNAME}/sites/${var.NGWAF_SITENAME}/edgeDeployment/${fastly_service_vcl.frontend-vcl-service.id} -H x-api-user:${var.NGWAF_EMAIL} -H x-api-token:${var.NGWAF_TOKEN} -H Fastly-Key:${var.FASTLY_API_KEY} -H Content-Type:application/json"]

#   depends_on = [
#     null_resource.create_or_update_ngwaf_edge_deploy,
#     fastly_service_vcl.frontend-vcl-service,
#   ]
# }

# output "fastly_service_output" {
#   value = fastly_service_vcl.frontend-vcl-service.id
# }

#### Fastly VCL Service - End

output "how_to_enjoy" {
  value = "curl -i https://${var.USER_VCL_SERVICE_DOMAIN_NAME}/anything/whydopirates?likeurls=theargs"
}