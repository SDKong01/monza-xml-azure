# =============================================================================
# Authentication ALB Module
# =============================================================================
# Description: Creates an internet-facing Application Load Balancer and target
# group for the Keycloak authentication service

# Application Load Balancer for Authentication Service
resource "aws_lb" "auth" {
  name               = "${var.project_name}-auth-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  # Enable HTTP/2 for better performance
  enable_http2 = true

  # Drop invalid header fields for security
  drop_invalid_header_fields = true

  # Standard idle timeout for authentication flows
  idle_timeout = 60

  tags = merge(var.common_tags, {
    Name      = "${var.project_name}-auth-${var.environment}-alb"
    Service   = "authentication"
    Component = "load-balancer"
    ManagedBy = "Terraform"
  })
}


