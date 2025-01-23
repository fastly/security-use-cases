#### mTLS configuration - start

resource "null_resource" "generate_ca" {
  provisioner "local-exec" {
    command = <<EOT
      mkdir -p certs &&
      openssl genrsa 4096 > certs/ca-key.pem &&
      openssl req -new -x509 -nodes -days 3650 -key certs/ca-key.pem -subj "/CN=mtl-demo-ca" > certs/ca-cert.pem
    EOT
  }
}

resource "null_resource" "generate_client_cert" {
  provisioner "local-exec" {
    command = <<EOT
      openssl req -newkey rsa:2048 -days 365 -nodes -keyout certs/client-key1.pem -subj "/CN=client1" > certs/client-req.pem &&
      openssl x509 -req -in certs/client-req.pem -days 365 -CA certs/ca-cert.pem -CAkey certs/ca-key.pem -set_serial 01 > certs/client-cert1.pem
    EOT
  }

  depends_on = [null_resource.generate_ca]
}

resource "fastly_tls_subscription" "certainly_tls" {
  domains               = [for domain in fastly_service_vcl.frontend-vcl-service.domain : domain.name]
  certificate_authority = "certainly"
}

resource "fastly_tls_subscription_validation" "certainly_tls" {
  subscription_id = fastly_tls_subscription.certainly_tls.id
}

data "fastly_tls_configuration" "default" {
  default    = true
  depends_on = [fastly_tls_subscription_validation.certainly_tls]
}

data "fastly_tls_activation" "mtls_demo" {
  # domain     = [for domain in fastly_service_vcl.frontend-vcl-service.domain : domain.name]
  domain     = tolist(fastly_service_vcl.frontend-vcl-service.domain)[0].name
}

resource "fastly_tls_mutual_authentication" "mtls_demo" {
  activation_ids = [data.fastly_tls_activation.mtls_demo.id]
  name = "mtls demo - mtls-demo.livewaflove.com"
  cert_bundle    = file("${path.module}/certs/ca-cert.pem")
  enforced       = false
}


#### mTLS config - end