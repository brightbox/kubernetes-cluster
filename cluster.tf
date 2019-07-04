resource "brightbox_server_group" "k8s" {
  name = local.cluster_fqdn
}

resource "brightbox_firewall_policy" "k8s" {
  name         = brightbox_server_group.k8s.name
  server_group = brightbox_server_group.k8s.id
}

resource "brightbox_firewall_rule" "k8s_intra_group" {
  source          = brightbox_server_group.k8s.id
  firewall_policy = brightbox_firewall_policy.k8s.id
}

resource "brightbox_firewall_rule" "k8s_ssh" {
  destination_port = "22"
  protocol         = "tcp"
  source           = "any"
  description      = "SSH access from anywhere"
  firewall_policy  = brightbox_firewall_policy.k8s.id
}

resource "brightbox_firewall_rule" "k8s_cluster" {
  count            = length(var.management_source)
  destination_port = local.service_port
  protocol         = "tcp"
  source           = var.management_source[count.index]
  description      = "API access"
  firewall_policy  = brightbox_firewall_policy.k8s.id
}

resource "brightbox_firewall_rule" "k8s_outbound" {
  destination     = "any"
  description     = "Outbound internet access"
  firewall_policy = brightbox_firewall_policy.k8s.id
}

resource "brightbox_firewall_rule" "k8s_icmp" {
  protocol        = "icmp"
  source          = "any"
  icmp_type_name  = "any"
  firewall_policy = brightbox_firewall_policy.k8s.id
}

resource "brightbox_api_client" "controller_client" {
  name              = "Cloud Controller ${var.cluster_name}"
  permissions_group = "full"
}

