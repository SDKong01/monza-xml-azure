# =============================================================================
# Target Groups Module
# =============================================================================
# Description: Creates and manages target groups for various services

# Target Group for Keycloak Authentication Service
resource "aws_lb_target_group" "keycloak" {
  count = var.create_keycloak_target_group ? 1 : 0

  name        = "${var.project_name}-keycloak-${var.environment}-tg"
  port        = var.keycloak_target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # Health check configuration optimized for Keycloak
  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = var.keycloak_health_check_path
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  # Connection draining for graceful instance removal
  deregistration_delay = 30

  # Stickiness disabled for stateless authentication
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = false
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-keycloak-${var.environment}-tg"
    Service     = "authentication"
    Component   = "target-group"
    Application = "keycloak"
    ManagedBy   = "Terraform"
  })
}
