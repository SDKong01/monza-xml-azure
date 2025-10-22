# =============================================================================
# Route 53 Records Module
# =============================================================================
# Description: Creates Route 53 DNS records, including ALB alias records

# Authentication ALB DNS Record (A record with alias to ALB)
resource "aws_route53_record" "auth_alb" {
  count = var.create_auth_dns_record ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "${var.auth_subdomain}.${var.base_domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = var.evaluate_target_health
  }
}

# SENNA App Runner DNS Record (CNAME record to App Runner URL)
resource "aws_route53_record" "senna_app_runner" {
  count = var.create_senna_dns_record ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "${var.senna_subdomain}.${var.base_domain}"
  type    = "CNAME"
  ttl     = 300

  records = [var.senna_app_runner_url]

}

# SENNA Certificate Validation Records
resource "aws_route53_record" "senna_certificate_validation" {
  for_each = var.create_senna_certificate_validation_records ? {
    for record in var.senna_certificate_validation_records : record.name => record
  } : {}

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300

  records = [each.value.value]
}

# Kainam Platform App Runner DNS Record (CNAME record to App Runner URL)
resource "aws_route53_record" "kainam_platform_app_runner" {
  count = var.create_kainam_platform_dns_record ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = "${var.kainam_platform_subdomain}.${var.base_domain}"
  type    = "CNAME"
  ttl     = 300

  records = [var.kainam_platform_app_runner_url]
}