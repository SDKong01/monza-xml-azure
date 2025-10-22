# =============================================================================
# Target Groups Module Outputs
# =============================================================================
# Description: Outputs from the Target Groups module for use by other modules

# Keycloak Target Group Outputs
output "keycloak_target_group_arn" {
  description = "ARN of the Keycloak target group"
  value       = var.create_keycloak_target_group ? aws_lb_target_group.keycloak[0].arn : null
}

output "keycloak_target_group_arn_suffix" {
  description = "ARN suffix of the Keycloak target group for CloudWatch metrics"
  value       = var.create_keycloak_target_group ? aws_lb_target_group.keycloak[0].arn_suffix : null
}

output "keycloak_target_group_name" {
  description = "Name of the Keycloak target group"
  value       = var.create_keycloak_target_group ? aws_lb_target_group.keycloak[0].name : null
}

output "keycloak_target_group_port" {
  description = "Port configured for the Keycloak target group"
  value       = var.create_keycloak_target_group ? aws_lb_target_group.keycloak[0].port : null
}

output "keycloak_health_check_path" {
  description = "Health check path configured for the Keycloak target group"
  value       = var.keycloak_health_check_path
}

# Additional outputs for target group attachments
output "keycloak_target_group_id" {
  description = "ID of the Keycloak target group for use with attachments"
  value       = var.create_keycloak_target_group ? aws_lb_target_group.keycloak[0].id : null
}
