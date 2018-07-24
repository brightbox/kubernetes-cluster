resource "tls_private_key" "k8s_ca" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "k8s_ca" {
  key_algorithm   = "${tls_private_key.k8s_ca.algorithm}"
  private_key_pem = "${tls_private_key.k8s_ca.private_key_pem}"

  subject {
    common_name         = "${brightbox_server_group.k8s.name}"
    organizational_unit = "apiserver"
  }

  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "cert_signing",
  ]

  is_ca_certificate = true
}

resource "tls_private_key" "cloud-controller" {
  algorithm = "RSA"
}

resource "tls_cert_request" "cloud-controller" {
  key_algorithm   = "${tls_private_key.cloud-controller.algorithm}"
  private_key_pem = "${tls_private_key.cloud-controller.private_key_pem}"

  subject {
    common_name = "brightbox-cloud-controller"
  }

  dns_names = [
    "${brightbox_server.k8s_master.hostname}",
    "${brightbox_server.k8s_master.fqdn}",
    "${brightbox_server.k8s_master.ipv6_hostname}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.${var.cluster_domainname}",
  ]

  ip_addresses = [
    "${brightbox_server.k8s_master.ipv4_address_private}",
    "${brightbox_server.k8s_master.ipv6_address}",
  ]
}

resource "tls_locally_signed_cert" "cloud-controller" {
  cert_request_pem   = "${tls_cert_request.cloud-controller.cert_request_pem}"
  ca_key_algorithm   = "${tls_private_key.k8s_ca.algorithm}"
  ca_private_key_pem = "${tls_private_key.k8s_ca.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.k8s_ca.cert_pem}"

  validity_period_hours = "${var.validity_period}"

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
