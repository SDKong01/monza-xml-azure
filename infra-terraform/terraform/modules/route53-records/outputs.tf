# =============================================================================
# Route 53 Records Module Outputs
# =============================================================================
# Description: Outputs from the Route 53 Records module

# Authentication DNS Record Outputs
output "auth_dns_record_name" {
  description = "Full DNS name of the authentication record"
  value       = var.create_auth_dns_record ? aws_route53_record.auth_alb[0].name : null
}

output "auth_dns_record_fqdn" {
  description = "Fully qualified domain name of the authentication record"
  value       = var.create_auth_dns_record ? aws_route53_record.auth_alb[0].fqdn : null
}

output "auth_dns_record_type" {
  description = "DNS record type for the authentication record"
  value       = var.create_auth_dns_record ? aws_route53_record.auth_alb[0].type : null
}

output "auth_dns_zone_id" {
  description = "Route 53 hosted zone ID used for the authentication record"
  value       = var.hosted_zone_id
}

# Alias Configuration Outputs
output "auth_alias_target" {
  description = "Alias target configuration for the authentication record"
  value = var.create_auth_dns_record ? {
    dns_name               = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  } : null
}

# Full URL Output
output "auth_service_url" {
  description = "Full HTTPS URL for the authentication service"
  value       = var.create_auth_dns_record ? "https://${var.auth_subdomain}.${var.base_domain}" : null
}

# Configuration Summary
output "dns_configuration_summary" {
  description = "Summary of the DNS configuration"
  value = var.create_auth_dns_record ? {
    subdomain    = var.auth_subdomain
    base_domain  = var.base_domain
    full_domain  = "${var.auth_subdomain}.${var.base_domain}"
    record_type  = "A (Alias)"
    target_alb   = var.alb_dns_name
    health_check = var.evaluate_target_health
    environment  = var.environment
  } : null
}

# ===================================
# SENNA App Runner DNS Record Outputs
# ===================================

output "senna_dns_record_name" {
  description = "Full DNS name of the SENNA record"
  value       = var.create_senna_dns_record ? aws_route53_record.senna_app_runner[0].name : null
}

output "senna_dns_record_fqdn" {
  description = "Fully qualified domain name of the SENNA record"
  value       = var.create_senna_dns_record ? aws_route53_record.senna_app_runner[0].fqdn : null
}

output "senna_service_url" {
  description = "Full HTTPS URL for the SENNA service"
  value       = var.create_senna_dns_record ? "https://${var.senna_subdomain}.${var.base_domain}" : null
}

output "senna_dns_configuration_summary" {
  description = "SENNA DNS configuration summary"
  value = var.create_senna_dns_record ? {
    subdomain         = var.senna_subdomain
    base_domain       = var.base_domain
    full_domain       = "${var.senna_subdomain}.${var.base_domain}"
    record_type       = "CNAME"
    target_app_runner = var.senna_app_runner_url
    ttl               = 300
    environment       = var.environment
  } : null
}

# ===================================
# SENNA Certificate Validation Outputs
# ===================================

output "senna_certificate_validation_records_created" {
  description = "Certificate validation records that were created in Route 53"
  value = var.create_senna_certificate_validation_records ? {
    for name, record in aws_route53_record.senna_certificate_validation : name => {
      name    = record.name
      type    = record.type
      values  = record.records
      fqdn    = record.fqdn
      zone_id = record.zone_id
    }
  } : {}
}

output "senna_certificate_validation_summary" {
  description = "Summary of certificate validation DNS records"
  value = var.create_senna_certificate_validation_records ? {
    records_count = length(var.senna_certificate_validation_records)
    domain        = "${var.senna_subdomain}.${var.base_domain}"
    status        = "DNS records created - certificate validation should complete automatically"
    next_steps    = "Monitor certificate status in ACM console or App Runner service"
  } : null
}

# ===================================
# Kainam Platform App Runner DNS Record Outputs
# ===================================

output "kainam_platform_dns_record_name" {
  description = "Full DNS name of the Kainam Platform record"
  value       = var.create_kainam_platform_dns_record ? aws_route53_record.kainam_platform_app_runner[0].name : null
}

output "kainam_platform_dns_record_fqdn" {
  description = "Fully qualified domain name of the Kainam Platform record"
  value       = var.create_kainam_platform_dns_record ? aws_route53_record.kainam_platform_app_runner[0].fqdn : null
}

output "kainam_platform_service_url" {
  description = "Full HTTPS URL for the Kainam Platform service"
  value       = var.create_kainam_platform_dns_record ? "https://${var.kainam_platform_subdomain}.${var.base_domain}" : null
}

output "kainam_platform_dns_configuration_summary" {
  description = "Kainam Platform DNS configuration summary"
  value = var.create_kainam_platform_dns_record ? {
    subdomain         = var.kainam_platform_subdomain
    base_domain       = var.base_domain
    full_domain       = "${var.kainam_platform_subdomain}.${var.base_domain}"
    record_type       = "CNAME"
    target_app_runner = var.kainam_platform_app_runner_url
    ttl               = 300
    environment       = var.environment
  } : null
}