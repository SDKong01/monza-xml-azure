# =============================================================================
# Authentication ALB Module Outputs
# =============================================================================
# Description: Outputs from the Authentication ALB module for use by other
# modules and environment configurations

output "alb_arn" {
  description = "ARN of the Authentication Application Load Balancer"
  value       = aws_lb.auth.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix of the Authentication ALB for CloudWatch metrics"
  value       = aws_lb.auth.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the Authentication ALB"
  value       = aws_lb.auth.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID of the Authentication ALB for DNS alias records"
  value       = aws_lb.auth.zone_id
}

output "alb_security_group_id" {
  description = "Security group ID associated with the Authentication ALB"
  value       = var.security_group_id
}


