resource "tls_private_key" "k8s_ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "k8s_ca" {
  key_algorithm   = "${tls_private_key.k8s_ca.algorithm}"
  private_key_pem = "${tls_private_key.k8s_ca.private_key_pem}"

  subject {
    common_name         = "apiserver"
    organizational_unit = "${brightbox_server_group.k8s.name}"
  }

  validity_period_hours = "${local.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}
