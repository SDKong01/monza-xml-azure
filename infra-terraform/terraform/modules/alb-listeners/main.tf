# =============================================================================
# ALB Listeners Module
# =============================================================================
# Description: Creates ALB listeners for HTTP redirect and HTTPS forwarding

# HTTP Listener - Redirects to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = tostring(var.https_port)
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = merge(var.common_tags, {
    Name         = "${var.project_name}-auth-${var.environment}-http-listener"
    Service      = "authentication"
    Component    = "listener"
    ListenerType = "http-redirect"
    ManagedBy    = "Terraform"
  })
}

# HTTPS Listener - Forwards to Target Group
resource "aws_lb_listener" "https_forward" {
  load_balancer_arn = var.load_balancer_arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }

  tags = merge(var.common_tags, {
    Name         = "${var.project_name}-auth-${var.environment}-https-listener"
    Service      = "authentication"
    Component    = "listener"
    ListenerType = "https-forward"
    ManagedBy    = "Terraform"
  })
}
