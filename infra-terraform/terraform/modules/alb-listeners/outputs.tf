# =============================================================================
# ALB Listeners Module Outputs
# =============================================================================
# Description: Outputs from the ALB Listeners module

# HTTP Listener Outputs
output "http_listener_arn" {
  description = "ARN of the HTTP listener (redirect)"
  value       = aws_lb_listener.http_redirect.arn
}

output "http_listener_port" {
  description = "Port of the HTTP listener"
  value       = aws_lb_listener.http_redirect.port
}

# HTTPS Listener Outputs
output "https_listener_arn" {
  description = "ARN of the HTTPS listener (forward)"
  value       = aws_lb_listener.https_forward.arn
}

output "https_listener_port" {
  description = "Port of the HTTPS listener"
  value       = aws_lb_listener.https_forward.port
}

output "https_ssl_policy" {
  description = "SSL policy used by the HTTPS listener"
  value       = aws_lb_listener.https_forward.ssl_policy
}

output "https_certificate_arn" {
  description = "Certificate ARN used by the HTTPS listener"
  value       = aws_lb_listener.https_forward.certificate_arn
}

# Target Group Integration
output "target_group_arn" {
  description = "Target group ARN that HTTPS traffic is forwarded to"
  value       = var.target_group_arn
}

# Listener Configuration Summary
output "redirect_configuration" {
  description = "HTTP to HTTPS redirect configuration summary"
  value = {
    from_port     = aws_lb_listener.http_redirect.port
    from_protocol = "HTTP"
    to_port       = var.https_port
    to_protocol   = "HTTPS"
    status_code   = "HTTP_301"
  }
}
