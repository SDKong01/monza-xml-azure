# EC2 Keycloak Module Outputs
# Provides access to Keycloak infrastructure resources for integration with other modules

# ===================================
# EC2 INSTANCE OUTPUTS
# ===================================

output "instance_id" {
  description = "ID of the Keycloak EC2 instance"
  value       = aws_instance.keycloak.id
}

output "instance_arn" {
  description = "ARN of the Keycloak EC2 instance"
  value       = aws_instance.keycloak.arn
}

output "instance_private_ip" {
  description = "Private IP address of the Keycloak EC2 instance"
  value       = aws_instance.keycloak.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the Keycloak EC2 instance (if assigned)"
  value       = aws_instance.keycloak.public_ip
}

output "instance_private_dns" {
  description = "Private DNS name of the Keycloak EC2 instance"
  value       = aws_instance.keycloak.private_dns
}

output "instance_public_dns" {
  description = "Public DNS name of the Keycloak EC2 instance (if assigned)"
  value       = aws_instance.keycloak.public_dns
}

output "instance_availability_zone" {
  description = "Availability zone of the Keycloak EC2 instance"
  value       = aws_instance.keycloak.availability_zone
}

output "instance_state" {
  description = "State of the Keycloak EC2 instance"
  value       = aws_instance.keycloak.instance_state
}

# ===================================
# SECURITY GROUP OUTPUTS
# ===================================

output "security_group_id" {
  description = "ID of the Keycloak security group"
  value       = aws_security_group.keycloak.id
}

output "security_group_arn" {
  description = "ARN of the Keycloak security group"
  value       = aws_security_group.keycloak.arn
}

output "security_group_name" {
  description = "Name of the Keycloak security group"
  value       = aws_security_group.keycloak.name
}

# ===================================
# IAM OUTPUTS
# ===================================

output "iam_role_arn" {
  description = "ARN of the Keycloak IAM role (if created)"
  value       = var.create_iam_role ? aws_iam_role.keycloak_ec2_role[0].arn : null
}

output "iam_role_name" {
  description = "Name of the Keycloak IAM role (if created)"
  value       = var.create_iam_role ? aws_iam_role.keycloak_ec2_role[0].name : null
}

output "iam_instance_profile_arn" {
  description = "ARN of the Keycloak IAM instance profile (if created)"
  value       = var.create_iam_role ? aws_iam_instance_profile.keycloak_ec2_profile[0].arn : null
}

output "iam_instance_profile_name" {
  description = "Name of the Keycloak IAM instance profile (if created)"
  value       = var.create_iam_role ? aws_iam_instance_profile.keycloak_ec2_profile[0].name : null
}

output "iam_policy_arn" {
  description = "ARN of the Keycloak IAM policy (if created)"
  value       = var.create_iam_role ? aws_iam_policy.keycloak_ec2_policy[0].arn : null
}

# ===================================
# SSH ACCESS OUTPUTS
# ===================================

output "ssh_key_name" {
  description = "Name of the SSH key pair for Keycloak instance access"
  value       = var.ssh_public_key != null ? aws_key_pair.keycloak_ssh[0].key_name : var.key_pair_name
}

output "ssh_key_fingerprint" {
  description = "Fingerprint of the SSH key pair (if created)"
  value       = var.ssh_public_key != null ? aws_key_pair.keycloak_ssh[0].fingerprint : null
}

output "ssh_connection_command" {
  description = "SSH connection command for the Keycloak instance"
  value       = var.ssh_public_key != null ? "ssh -i ~/.ssh/${aws_key_pair.keycloak_ssh[0].key_name}.pem ubuntu@${aws_instance.keycloak.private_ip}" : null
  sensitive   = true
}

output "ssh_access_enabled" {
  description = "Whether SSH access is enabled for the instance"
  value       = var.enable_ssh_access
}

output "ssh_trusted_ip_ranges" {
  description = "List of trusted IP ranges for SSH access"
  value       = var.ssh_trusted_ip_ranges
  sensitive   = true
}

# ===================================
# SERVICE CONFIGURATION OUTPUTS
# ===================================

output "keycloak_hostname" {
  description = "Hostname for the Keycloak service"
  value       = var.keycloak_hostname
}

output "keycloak_http_port" {
  description = "HTTP port for the Keycloak service"
  value       = var.keycloak_http_port
}

output "keycloak_internal_url" {
  description = "Internal URL for accessing Keycloak service"
  value       = "http://${aws_instance.keycloak.private_ip}:${var.keycloak_http_port}"
}

output "keycloak_health_check_url" {
  description = "Health check URL for Keycloak service"
  value       = "http://${aws_instance.keycloak.private_ip}:${var.keycloak_http_port}/health/ready"
}

output "keycloak_admin_console_url" {
  description = "Admin console URL for Keycloak service (external)"
  value       = "https://${var.keycloak_hostname}/admin"
}

# ===================================
# NETWORK CONFIGURATION OUTPUTS
# ===================================

output "vpc_id" {
  description = "VPC ID where the Keycloak instance is deployed"
  value       = var.vpc_id
}

output "subnet_id" {
  description = "Subnet ID where the Keycloak instance is deployed"
  value       = var.subnet_id
}

output "availability_zone" {
  description = "Availability zone where the Keycloak instance is deployed"
  value       = data.aws_subnet.selected.availability_zone
}

# ===================================
# TARGET GROUP INTEGRATION OUTPUTS
# ===================================

output "target_group_attachment_config" {
  description = "Configuration for ALB target group attachment"
  value = {
    target_id = aws_instance.keycloak.id
    port      = var.keycloak_http_port
  }
}

# ===================================
# MONITORING OUTPUTS
# ===================================

output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name for Keycloak logs"
  value       = "/aws/ec2/keycloak/${var.environment}"
}

output "instance_monitoring_enabled" {
  description = "Whether detailed monitoring is enabled for the instance"
  value       = var.enable_detailed_monitoring
}

# ===================================
# STORAGE OUTPUTS
# ===================================

output "root_volume_id" {
  description = "ID of the root EBS volume"
  value       = aws_instance.keycloak.root_block_device[0].volume_id
}

output "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  value       = var.root_volume_size
}

output "root_volume_encrypted" {
  description = "Whether the root EBS volume is encrypted"
  value       = var.root_volume_encrypted
}

# ===================================
# DEPLOYMENT CONFIGURATION OUTPUTS
# ===================================

output "container_name" {
  description = "Name of the Keycloak Docker container"
  value       = var.container_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for Keycloak Docker image"
  value       = var.ecr_repository_url
}

output "image_tag" {
  description = "Docker image tag deployed"
  value       = var.image_tag
}

# ===================================
# DATABASE CONFIGURATION OUTPUTS
# ===================================

output "database_endpoint" {
  description = "RDS endpoint for Keycloak database"
  value       = var.rds_endpoint
}

output "database_name" {
  description = "Database name for Keycloak"
  value       = var.database_name
}

output "database_port" {
  description = "Database port for Keycloak"
  value       = var.database_port
}

# ===================================
# SECRETS CONFIGURATION OUTPUTS
# ===================================

output "database_secret_name" {
  description = "AWS Secrets Manager secret name for database credentials"
  value       = var.database_secret_name
}

output "keycloak_secret_name" {
  description = "AWS Secrets Manager secret name for Keycloak admin credentials"
  value       = var.keycloak_secret_name
}

# ===================================
# SUMMARY OUTPUT
# ===================================

output "keycloak_service_summary" {
  description = "Summary of Keycloak service deployment"
  value = {
    # Instance information
    instance = {
      id                = aws_instance.keycloak.id
      private_ip        = aws_instance.keycloak.private_ip
      availability_zone = aws_instance.keycloak.availability_zone
      state             = aws_instance.keycloak.instance_state
    }

    # Service configuration
    service = {
      hostname          = var.keycloak_hostname
      port              = var.keycloak_http_port
      internal_url      = "http://${aws_instance.keycloak.private_ip}:${var.keycloak_http_port}"
      health_check_url  = "http://${aws_instance.keycloak.private_ip}:${var.keycloak_http_port}/health/ready"
      admin_console_url = "https://${var.keycloak_hostname}/admin"
    }

    # Security configuration
    security = {
      security_group_id = aws_security_group.keycloak.id
      iam_role_arn      = var.create_iam_role ? aws_iam_role.keycloak_ec2_role[0].arn : null
      volume_encrypted  = var.root_volume_encrypted
    }

    # Network configuration
    network = {
      vpc_id             = var.vpc_id
      subnet_id          = var.subnet_id
      private_deployment = !var.associate_public_ip_address
    }

    # Target group attachment
    target_group = {
      target_id = aws_instance.keycloak.id
      port      = var.keycloak_http_port
    }
  }
}
