terraform {
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      version = "0.11.7"
    }
  }
}

provider "volterra" {   
    #api_p12_file = var.api_p12_file
    #url          = var.api_url    
}

locals {
  demoFQDN                  = "${var.custName}.${var.demoDomain}"
}


resource "volterra_healthcheck" "healthcheck" {
    name                    = format("%s-tcp-healthcheck", var.custName)
    namespace               = var.demoNameSpace
    tcp_health_check {
    }
    healthy_threshold       = var.healthy_threshold
    interval                = var.interval
    timeout                 = var.timeout
    unhealthy_threshold     = var.unhealthy_threshold
}

resource "volterra_origin_pool" "origin_pool" {
    name                    = format("%s-origin-pool", var.custName)
    namespace               = var.demoNameSpace
    endpoint_selection      = "LOCAL_PREFERRED"
    loadbalancer_algorithm  = "LB_OVERRIDE"
#    healthcheck {
#      name                  = volterra_healthcheck.healthcheck.name
#      namespace             = volterra_healthcheck.healthcheck.namespace
#      tenant                = var.xcTenant
#    }
    origin_servers {
            public_name {
                dns_name = var.originFQDN
            }
        }
    port                    = 443 
    no_tls = true    
}

resource "volterra_tcp_loadbalancer" "tcp_lb" {
    name                    = format("%s-tcp-lb", var.custName)
    namespace               = var.demoNameSpace    
    description             = format("TCP Load balancer for %s domain", var.originFQDN )
    domains                 = [format("%s", local.demoFQDN)]
    advertise_on_public_default_vip = true
    dns_volterra_managed            = true
    listen_port             = 443
    with_sni                = true

    origin_pools_weights {
      
        pool  {
          name = volterra_origin_pool.origin_pool.name
          namespace = var.demoNameSpace
          tenant = var.xcTenant
        }

      }
    
}
