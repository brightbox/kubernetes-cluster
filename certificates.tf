resource "tls_private_key" "k8s_ca" {
  algorithm = "RSA"
}

##resource "tls_private_key" "k8s_etcd_ca" {
##  algorithm = "${tls_private_key.k8s_ca.algorithm}"
##}
##
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

##resource "tls_self_signed_cert" "k8s_etcd_ca" {
##  key_algorithm   = "${tls_private_key.k8s_etcd_ca.algorithm}"
##  private_key_pem = "${tls_private_key.k8s_etcd_ca.private_key_pem}"
##
##  subject {
##    common_name         = "${brightbox_server_group.k8s.name}"
##    organizational_unit = "etd"
##  }
##
##  validity_period_hours = "${var.validity_period}"
##
##  allowed_uses = [
##    "key_encipherment",
##    "digital_signature",
##    "cert_signing",
##  ]
##
##  is_ca_certificate = true
##}
##
##resource "tls_private_key" "etcd-peer" {
##  algorithm = "RSA"
##}
##
##resource "tls_cert_request" "etcd-peer" {
##  key_algorithm   = "${tls_private_key.etcd-peer.algorithm}"
##  private_key_pem = "${tls_private_key.etcd-peer.private_key_pem}"
##
##  subject {
##    common_name = "kube-etcd-peer"
##  }
##
##  dns_names = [
##    "${brightbox_server.k8s_master.hostname}",
##    "${brightbox_server.k8s_master.fqdn}",
##    "${brightbox_server.k8s_master.ipv6_hostname}",
##  ]
##
##  ip_addresses = [
##    "${brightbox_server.k8s_master.ipv4_address_private}",
##    "${brightbox_server.k8s_master.ipv6_address}",
##  ]
##}
##
##resource "tls_locally_signed_cert" "etcd-peer" {
##  cert_request_pem   = "${tls_cert_request.etcd-peer.cert_request_pem}"
##  ca_key_algorithm   = "${tls_private_key.k8s_etcd_ca.algorithm}"
##  ca_private_key_pem = "${tls_private_key.k8s_etcd_ca.private_key_pem}"
##  ca_cert_pem        = "${tls_self_signed_cert.k8s_etcd_ca.cert_pem}"
##
##  validity_period_hours = "${var.validity_period}"
##
##  allowed_uses = [
##    "key_encipherment",
##    "digital_signature",
##    "server_auth",
##    "client_auth",
##  ]
##}
##
##resource "tls_private_key" "etcd-server" {
##  algorithm = "RSA"
##}
##
##resource "tls_cert_request" "etcd-server" {
##  key_algorithm   = "${tls_private_key.etcd-server.algorithm}"
##  private_key_pem = "${tls_private_key.etcd-server.private_key_pem}"
##
##  subject {
##    common_name = "kube-etcd"
##  }
##
##  dns_names = [
##    "localhost",
##  ]
##
##  ip_addresses = [
##    "127.0.0.1",
##    "::1",
##  ]
##}
##
##resource "tls_locally_signed_cert" "etcd-server" {
##  cert_request_pem   = "${tls_cert_request.etcd-server.cert_request_pem}"
##  ca_key_algorithm   = "${tls_private_key.k8s_etcd_ca.algorithm}"
##  ca_private_key_pem = "${tls_private_key.k8s_etcd_ca.private_key_pem}"
##  ca_cert_pem        = "${tls_self_signed_cert.k8s_etcd_ca.cert_pem}"
##
##  validity_period_hours = "${var.validity_period}"
##
##  allowed_uses = [
##    "key_encipherment",
##    "digital_signature",
##    "server_auth",
##  ]
##}
##
##resource "tls_private_key" "etcd-healthcheck-client" {
##  algorithm = "RSA"
##}
##
##resource "tls_cert_request" "etcd-healthcheck-client" {
##  key_algorithm   = "${tls_private_key.etcd-healthcheck-client.algorithm}"
##  private_key_pem = "${tls_private_key.etcd-healthcheck-client.private_key_pem}"
##
##  subject {
##    common_name  = "kube-etcd-healthcheck-client"
##    organization = "system:masters"
##  }
##}
##
##resource "tls_locally_signed_cert" "etcd-healthcheck-client" {
##  cert_request_pem   = "${tls_cert_request.etcd-healthcheck-client.cert_request_pem}"
##  ca_key_algorithm   = "${tls_private_key.k8s_etcd_ca.algorithm}"
##  ca_private_key_pem = "${tls_private_key.k8s_etcd_ca.private_key_pem}"
##  ca_cert_pem        = "${tls_self_signed_cert.k8s_etcd_ca.cert_pem}"
##
##  validity_period_hours = "${var.validity_period}"
#
#  allowed_uses = [
#    "key_encipherment",
#    "digital_signature",
#    "client_auth",
#  ]
#}
#
#resource "tls_private_key" "apiserver-etcd-client" {
#  algorithm = "RSA"
#}
#
#resource "tls_cert_request" "apiserver-etcd-client" {
#  key_algorithm   = "${tls_private_key.apiserver-etcd-client.algorithm}"
#  private_key_pem = "${tls_private_key.apiserver-etcd-client.private_key_pem}"
#
#  subject {
#    common_name  = "kube-apiserver-etcd-client"
#    organization = "system:masters"
#  }
#}
#
#resource "tls_locally_signed_cert" "apiserver-etcd-client" {
#  cert_request_pem   = "${tls_cert_request.apiserver-etcd-client.cert_request_pem}"
#  ca_key_algorithm   = "${tls_private_key.k8s_etcd_ca.algorithm}"
#  ca_private_key_pem = "${tls_private_key.k8s_etcd_ca.private_key_pem}"
#  ca_cert_pem        = "${tls_self_signed_cert.k8s_etcd_ca.cert_pem}"
#
#  validity_period_hours = "${var.validity_period}"
#
#  allowed_uses = [
#    "key_encipherment",
#    "digital_signature",
#    "client_auth",
#  ]
#}
#
#resource "tls_private_key" "apiserver-kubelet-client" {
#  algorithm = "RSA"
#}
#
#resource "tls_cert_request" "apiserver-kubelet-client" {
#  key_algorithm   = "${tls_private_key.apiserver-kubelet-client.algorithm}"
#  private_key_pem = "${tls_private_key.apiserver-kubelet-client.private_key_pem}"
#
#  subject {
#    common_name  = "kube-apiserver-kubelet-client"
#    organization = "system:masters"
#  }
#}
#
#resource "tls_locally_signed_cert" "apiserver-kubelet-client" {
#  cert_request_pem   = "${tls_cert_request.apiserver-kubelet-client.cert_request_pem}"
#  ca_key_algorithm   = "${tls_private_key.k8s_ca.algorithm}"
#  ca_private_key_pem = "${tls_private_key.k8s_ca.private_key_pem}"
#  ca_cert_pem        = "${tls_self_signed_cert.k8s_ca.cert_pem}"
#
#  validity_period_hours = "${var.validity_period}"
#
#  allowed_uses = [
#    "key_encipherment",
#    "digital_signature",
#    "client_auth",
#  ]
#}
#
#resource "tls_private_key" "apiserver" {
#  algorithm = "RSA"
#}
#
#resource "tls_cert_request" "apiserver" {
#  key_algorithm   = "${tls_private_key.apiserver.algorithm}"
#  private_key_pem = "${tls_private_key.apiserver.private_key_pem}"
#
#  subject {
#    common_name = "kube-apiserver"
#  }
#
#  dns_names = [
#    "${brightbox_server.k8s_master.hostname}",
#    "${brightbox_server.k8s_master.fqdn}",
#    "${brightbox_server.k8s_master.ipv6_hostname}",
#    "kubernetes",
#    "kubernetes.default",
#    "kubernetes.default.svc",
#    "kubernetes.default.svc.${var.cluster_domainname}",
#  ]
#
#  ip_addresses = [
#    "${brightbox_server.k8s_master.ipv4_address_private}",
#    "${brightbox_server.k8s_master.ipv6_address}",
#  ]
#}
#
#resource "tls_locally_signed_cert" "apiserver" {
#  cert_request_pem   = "${tls_cert_request.apiserver.cert_request_pem}"
#  ca_key_algorithm   = "${tls_private_key.k8s_ca.algorithm}"
#  ca_private_key_pem = "${tls_private_key.k8s_ca.private_key_pem}"
#  ca_cert_pem        = "${tls_self_signed_cert.k8s_ca.cert_pem}"
#
#  validity_period_hours = "${var.validity_period}"
#
#  allowed_uses = [
#    "key_encipherment",
#    "digital_signature",
#    "server_auth",
#  ]
#}
#
#resource "tls_private_key" "k8s_sa" {
#  algorithm = "RSA"
#}
#
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

#resource "tls_private_key" "cloud-controller-apiserver-client" {
#  algorithm = "RSA"
#}
#
#resource "tls_cert_request" "cloud-controller-apiserver-client" {
#  key_algorithm   = "${tls_private_key.cloud-controller-apiserver-client.algorithm}"
#  private_key_pem = "${tls_private_key.cloud-controller-apiserver-client.private_key_pem}"
#
#  subject {
#    common_name = "${local.cloud_controller_username}"
#  }
#}
#
#resource "tls_locally_signed_cert" "cloud-controller-apiserver-client" {
#  cert_request_pem   = "${tls_cert_request.cloud-controller-apiserver-client.cert_request_pem}"
#  ca_key_algorithm   = "${tls_private_key.k8s_ca.algorithm}"
#  ca_private_key_pem = "${tls_private_key.k8s_ca.private_key_pem}"
#  ca_cert_pem        = "${tls_self_signed_cert.k8s_ca.cert_pem}"
#
#  validity_period_hours = "${var.validity_period}"
#
#  allowed_uses = [
#    "key_encipherment",
#    "digital_signature",
#    "client_auth",
#  ]
#}

