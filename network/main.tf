#================================== VPC ====================================
resource "google_compute_network" "vpc" {
  name = var.gcp_vpc_name
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes_on_create
}


#================================ SUBNETS ==================================

locals {
    subnets = {
        for x in var.subnets :
        "${x.subnet_region}/${x.subnet_name}" => x
    }
}

resource "google_compute_subnetwork" "subnets" {
    for_each = local.subnets
    name = each.value.subnet_name
    ip_cidr_range = each.value.subnet_ip_range
    region = each.value.subnet_region
    network = google_compute_network.vpc.id
    description = lookup(each.value, "description", null)
    private_ip_google_access = lookup(each.value, "subnet_private_access", null)
}

#================================ ROUTES ===================================

locals {
  routes = {
    for i, route in var.routes :
    lookup(route, "name", format("%s-%s-%d", lower(google_compute_network.vpc.id), "route", i)) => route
  }
}


resource "google_compute_route" "route" {
  for_each = local.routes

  network = google_compute_network.vpc.id

  name                   = each.key
  description            = lookup(each.value, "description", null)
  tags                   = compact(split(",", lookup(each.value, "tags", "")))
  dest_range             = lookup(each.value, "destination_range", null)
  next_hop_gateway       = lookup(each.value, "next_hop_internet", "false") == "true" ? "default-internet-gateway" : null
  next_hop_ip            = lookup(each.value, "next_hop_ip", null)
  next_hop_instance      = lookup(each.value, "next_hop_instance", null)
  next_hop_instance_zone = lookup(each.value, "next_hop_instance_zone", null)
  next_hop_vpn_tunnel    = lookup(each.value, "next_hop_vpn_tunnel", null)
  next_hop_ilb           = lookup(each.value, "next_hop_ilb", null)
  priority               = lookup(each.value, "priority", null)

  depends_on = [var.module_depends_on]
}


#============================= FIREWALL RULES ================================

resource "google_compute_firewall" "rules" {
  for_each                = { for r in var.firewall_rules : r.name => r }
  name                    = each.value.name
  direction               = each.value.direction
  network                 = google_compute_network.vpc.id
  source_ranges           = each.value.direction == "INGRESS" ? each.value.ranges : null
  destination_ranges      = each.value.direction == "EGRESS" ? each.value.ranges : null
  source_tags             = each.value.source_tags
  target_tags             = each.value.target_tags

  dynamic "allow" {
    for_each = lookup(each.value, "allow", [])
    content {
      protocol = allow.value.protocol
      ports    = lookup(allow.value, "ports", null)
    }
  }

  dynamic "deny" {
    for_each = lookup(each.value, "deny", [])
    content {
      protocol = deny.value.protocol
      ports    = lookup(deny.value, "ports", null)
    }
  }
}
