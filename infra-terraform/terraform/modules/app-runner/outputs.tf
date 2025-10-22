# ===================================
# App Runner Module - Outputs
# ===================================

output "service_arn" {
  description = "ARN of the App Runner service"
  value       = aws_apprunner_service.this.arn
}

output "service_id" {
  description = "ID of the App Runner service"
  value       = aws_apprunner_service.this.service_id
}

output "service_name" {
  description = "Name of the App Runner service"
  value       = aws_apprunner_service.this.service_name
}

output "service_url" {
  description = "Public URL of the App Runner service"
  value       = aws_apprunner_service.this.service_url
}

output "status" {
  description = "Current status of the App Runner service"
  value       = aws_apprunner_service.this.status
}

# ===================================
# Service Configuration Details
# ===================================

output "service_configuration" {
  description = "App Runner service configuration details"
  value = {
    name                  = aws_apprunner_service.this.service_name
    arn                   = aws_apprunner_service.this.arn
    url                   = aws_apprunner_service.this.service_url
    status                = aws_apprunner_service.this.status
    cpu                   = var.cpu
    memory                = var.memory
    port                  = var.port
    auto_deployments      = var.auto_deployments_enabled
    publicly_accessible   = var.is_publicly_accessible
    vpc_connector_arn     = var.create_vpc_connector ? aws_apprunner_vpc_connector.this[0].arn : null
    health_check_enabled  = var.health_check_enabled
    environment_variables = var.environment_variables
  }
  sensitive = true
}

# ===================================
# Connection Information
# ===================================

output "connection_info" {
  description = "Connection information for the App Runner service"
  value = {
    service_url         = aws_apprunner_service.this.service_url
    service_name        = aws_apprunner_service.this.service_name
    port                = var.port
    health_check_path   = var.health_check_enabled ? var.health_check_path : null
    publicly_accessible = var.is_publicly_accessible
  }
}

# ===================================
# VPC Connector Outputs
# ===================================

output "vpc_connector_arn" {
  description = "ARN of the VPC connector (if created)"
  value       = var.create_vpc_connector ? aws_apprunner_vpc_connector.this[0].arn : null
}

output "vpc_connector_name" {
  description = "Name of the VPC connector (if created)"
  value       = var.create_vpc_connector ? aws_apprunner_vpc_connector.this[0].vpc_connector_name : null
}

output "security_group_id" {
  description = "ID of the App Runner security group (if created)"
  value       = var.create_vpc_connector ? aws_security_group.app_runner[0].id : null
}

# ===================================
# Summary for Infrastructure Overview
# ===================================

output "app_runner_summary" {
  description = "Summary of App Runner service for infrastructure overview"
  value = {
    service_name = aws_apprunner_service.this.service_name
    service_url  = aws_apprunner_service.this.service_url
    status       = aws_apprunner_service.this.status
    compute = {
      cpu    = var.cpu
      memory = var.memory
    }
    networking = {
      port                = var.port
      publicly_accessible = var.is_publicly_accessible
      vpc_connector_arn   = var.create_vpc_connector ? aws_apprunner_vpc_connector.this[0].arn : null
      security_group_id   = var.create_vpc_connector ? aws_security_group.app_runner[0].id : null
    }
    deployment = {
      image_uri        = "${var.ecr_repository_url}:${var.image_tag}"
      auto_deployments = var.auto_deployments_enabled
    }
    health_check = {
      enabled  = var.health_check_enabled
      path     = var.health_check_enabled ? var.health_check_path : null
      protocol = var.health_check_enabled ? var.health_check_protocol : null
    }
    custom_domain = {
      enabled     = var.enable_custom_domain
      domain_name = var.enable_custom_domain ? var.custom_domain_name : null
      status      = var.enable_custom_domain ? aws_apprunner_custom_domain_association.this[0].status : null
    }
  }
}

# ===================================
# Custom Domain Outputs
# ===================================

output "custom_domain_association_status" {
  description = "Status of the custom domain association"
  value       = var.enable_custom_domain ? aws_apprunner_custom_domain_association.this[0].status : null
}

output "custom_domain_name" {
  description = "Custom domain name for the App Runner service"
  value       = var.enable_custom_domain ? var.custom_domain_name : null
}

output "dns_target" {
  description = "DNS target for the custom domain (CNAME record value)"
  value       = var.enable_custom_domain ? aws_apprunner_custom_domain_association.this[0].dns_target : null
}

output "certificate_validation_records" {
  description = "Certificate validation records that need to be added to DNS"
  value       = var.enable_custom_domain ? aws_apprunner_custom_domain_association.this[0].certificate_validation_records : []
}