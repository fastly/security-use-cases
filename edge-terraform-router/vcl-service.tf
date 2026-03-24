resource "fastly_service_vcl" "demo" {
  name = "demofastly"

  # Iterates over the array to create multiple domain blocks
  dynamic "domain" {
    for_each = var.fastly_routes
    content {
      name    = domain.value.domain_name
      comment = "Managed by Terraform"
    }
  }

  # Iterates over the array to create corresponding backends
  dynamic "backend" {
    for_each = var.fastly_routes
    content {
      address           = backend.value.origin_name
      # Creates a unique backend name based on the domain (e.g., "backend-example-com")
      name              = "backend-${replace(backend.value.domain_name, ".", "-")}"
      shield            = "iad-va-us"
      port              = 443
      use_ssl           = true
      ssl_cert_hostname = backend.value.origin_name
      ssl_sni_hostname  = backend.value.origin_name
      override_host     = backend.value.origin_name

      # Links this backend to the unique request condition below
      request_condition = "condition-${replace(backend.value.domain_name, ".", "-")}"
    }
  }

  # Iterates over the array to create routing conditions
  dynamic "condition" {
    for_each = var.fastly_routes
    content {
      # Matches the name defined in the backend block
      name      = "condition-${replace(condition.value.domain_name, ".", "-")}"
      priority  = 10
      # Evaluates the incoming request host against the domain variable
      statement = "req.http.host == \"${condition.value.domain_name}\""
      type      = "REQUEST"
    }
  }

  force_destroy = true
}