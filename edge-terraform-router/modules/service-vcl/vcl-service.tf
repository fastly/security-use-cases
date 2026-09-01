resource "fastly_service_vcl" "edge-terraform-router-demo" {
  name = "edge-terraform-router-demo"

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
      statement = "std.tolower(req.http.host) == \"${condition.value.domain_name}\""
      type      = "REQUEST"
    }
  }

  # Iterates over the array to create path-based request conditions
  dynamic "condition" {
    for_each = var.add_header_based_on_path
    content {
      # Creates a unique condition name based on the path (e.g., "path-condition-anything-foo")
      name      = "path-condition-${replace(trimprefix(condition.value.path, "/"), "/", "-")}"
      priority  = 10
      # Evaluates the incoming request path against the path variable
      statement = "req.url.path == \"${condition.value.path}\""
      type      = "REQUEST"
    }
  }

  # Iterates over the array to add request headers based on path conditions
  dynamic "header" {
    for_each = var.add_header_based_on_path
    content {
      # Creates a unique header action name based on the header name and path
      name              = "header-${header.value.header_name}-${replace(trimprefix(header.value.path, "/"), "/", "-")}"
      action            = "set"
      type              = "request"
      destination       = "http.${header.value.header_name}"
      source            = "\"${header.value.header_value}\""
      # Links this header action to the corresponding path condition above
      request_condition = "path-condition-${replace(trimprefix(header.value.path, "/"), "/", "-")}"
    }
  }

  force_destroy = true
}