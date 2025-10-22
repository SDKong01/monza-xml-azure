# ===================================
# App Runner Module - Main Configuration
# ===================================

# ===================================
# Local Values
# ===================================

locals {
  service_name   = "${var.project_name}-${var.service_name}-${var.environment}"
  connector_name = "${var.project_name}-ar-vpc-connector-${var.environment}"

  # Construct full image URI
  image_uri = "${var.ecr_repository_url}:${var.image_tag}"

  # Health check configuration
  health_check_config = var.health_check_enabled ? {
    healthy_threshold   = var.health_check_healthy_threshold
    interval            = var.health_check_interval
    path                = var.health_check_path
    protocol            = var.health_check_protocol
    timeout             = var.health_check_timeout
    unhealthy_threshold = var.health_check_unhealthy_threshold
  } : null

  # Network configuration
  network_config = var.create_vpc_connector ? {
    ingress_configuration = {
      is_publicly_accessible = var.is_publicly_accessible
    }
    egress_configuration = {
      egress_type       = "VPC"
      vpc_connector_arn = aws_apprunner_vpc_connector.this[0].arn
    }
    } : {
    ingress_configuration = {
      is_publicly_accessible = var.is_publicly_accessible
    }
    egress_configuration = {
      egress_type = "DEFAULT"
    }
  }

  # Tags
  tags = merge(
    var.common_tags,
    {
      Name        = local.service_name
      Service     = var.service_name
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Module      = "app-runner"
      Component   = "compute"
    }
  )
}

# ===================================
# Security Group for App Runner
# ===================================

resource "aws_security_group" "app_runner" {
  count = var.create_vpc_connector ? 1 : 0

  name        = "${local.service_name}-sg"
  description = "Security group for App Runner VPC connector - allows all outbound traffic"
  vpc_id      = var.vpc_id

  tags = merge(
    local.tags,
    {
      Name = "${local.service_name}-sg"
      Type = "App Runner Egress"
    }
  )
}

# Security Group Rules - Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "app_runner_all_outbound" {
  count = var.create_vpc_connector ? 1 : 0

  security_group_id = aws_security_group.app_runner[0].id
  description       = "Allow all outbound traffic for App Runner services"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "${local.service_name}-all-outbound"
  }
}

# ===================================
# VPC Connector for App Runner
# ===================================

resource "aws_apprunner_vpc_connector" "this" {
  count = var.create_vpc_connector ? 1 : 0

  vpc_connector_name = local.connector_name
  subnets            = var.subnet_ids
  security_groups    = [aws_security_group.app_runner[0].id]

  tags = merge(
    local.tags,
    {
      Name = local.connector_name
      Type = "VPC Connector"
    }
  )

  depends_on = [aws_security_group.app_runner]
}

# ===================================
# App Runner Service
# ===================================

resource "aws_apprunner_service" "this" {
  service_name = local.service_name

  # Source Configuration - ECR Image
  source_configuration {
    # ECR Access Role
    authentication_configuration {
      access_role_arn = var.access_role_arn
    }

    # Image Repository Configuration
    image_repository {
      image_identifier      = local.image_uri
      image_repository_type = "ECR"

      # Image Configuration
      image_configuration {
        port                          = var.port
        runtime_environment_variables = var.environment_variables
        runtime_environment_secrets   = var.environment_secrets
      }
    }

    # Auto Deployment Settings
    auto_deployments_enabled = var.auto_deployments_enabled
  }

  # Instance Configuration
  instance_configuration {
    cpu               = var.cpu
    memory            = var.memory
    instance_role_arn = var.instance_role_arn
  }

  # Network Configuration
  dynamic "network_configuration" {
    for_each = [local.network_config]
    content {
      # Ingress Configuration
      dynamic "ingress_configuration" {
        for_each = network_configuration.value.ingress_configuration != null ? [network_configuration.value.ingress_configuration] : []
        content {
          is_publicly_accessible = ingress_configuration.value.is_publicly_accessible
        }
      }

      # Egress Configuration
      dynamic "egress_configuration" {
        for_each = network_configuration.value.egress_configuration != null ? [network_configuration.value.egress_configuration] : []
        content {
          egress_type       = egress_configuration.value.egress_type
          vpc_connector_arn = lookup(egress_configuration.value, "vpc_connector_arn", null)
        }
      }
    }
  }

  # Health Check Configuration
  dynamic "health_check_configuration" {
    for_each = local.health_check_config != null ? [local.health_check_config] : []
    content {
      healthy_threshold   = health_check_configuration.value.healthy_threshold
      interval            = health_check_configuration.value.interval
      path                = health_check_configuration.value.path
      protocol            = health_check_configuration.value.protocol
      timeout             = health_check_configuration.value.timeout
      unhealthy_threshold = health_check_configuration.value.unhealthy_threshold
    }
  }

  # Tags
  tags = local.tags
}

# ===================================
# Custom Domain Association
# ===================================

resource "aws_apprunner_custom_domain_association" "this" {
  count = var.enable_custom_domain ? 1 : 0

  domain_name = var.custom_domain_name
  service_arn = aws_apprunner_service.this.arn

  # Wait for the App Runner service to be created first
  depends_on = [aws_apprunner_service.this]

  # Enable certificate validation
  enable_www_subdomain = false
}