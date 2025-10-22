# EC2 Instance Module Outputs
# Provides comprehensive outputs for integration with other modules and services

# Instance Information
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.this.arn
}

output "instance_name" {
  description = "Name of the EC2 instance"
  value       = local.instance_name
}

output "instance_type" {
  description = "Instance type of the EC2 instance"
  value       = aws_instance.this.instance_type
}

output "instance_state" {
  description = "Current state of the EC2 instance"
  value       = aws_instance.this.instance_state
}

# Network Information
output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.this.private_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.this.public_dns
}

output "private_dns" {
  description = "Private DNS name of the EC2 instance"
  value       = aws_instance.this.private_dns
}

output "subnet_id" {
  description = "Subnet ID where the instance is deployed"
  value       = aws_instance.this.subnet_id
}

output "vpc_id" {
  description = "VPC ID where the instance is deployed"
  value       = var.vpc_id
}

output "availability_zone" {
  description = "Availability zone of the EC2 instance"
  value       = aws_instance.this.availability_zone
}

# Security Information
output "security_group_id" {
  description = "ID of the security group (if created by this module)"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "security_group_name" {
  description = "Name of the security group (if created by this module)"
  value       = var.create_security_group ? aws_security_group.this[0].name : null
}

output "security_group_ids" {
  description = "List of security group IDs attached to the instance"
  value       = aws_instance.this.vpc_security_group_ids
}

# IAM Information
output "iam_role_arn" {
  description = "ARN of the IAM role (if created by this module)"
  value       = var.create_iam_role ? aws_iam_role.this[0].arn : null
}

output "iam_role_name" {
  description = "Name of the IAM role (if created by this module)"
  value       = var.create_iam_role ? aws_iam_role.this[0].name : null
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = var.create_iam_role ? aws_iam_instance_profile.this[0].name : var.existing_iam_instance_profile
}

output "iam_instance_profile_arn" {
  description = "ARN of the IAM instance profile (if created by this module)"
  value       = var.create_iam_role ? aws_iam_instance_profile.this[0].arn : null
}

# Key Pair Information
output "key_pair_name" {
  description = "Name of the key pair"
  value       = var.create_key_pair ? aws_key_pair.this[0].key_name : var.existing_key_pair_name
}

output "key_pair_id" {
  description = "ID of the key pair (if created by this module)"
  value       = var.create_key_pair ? aws_key_pair.this[0].key_pair_id : null
}

output "key_pair_fingerprint" {
  description = "Fingerprint of the key pair (if created by this module)"
  value       = var.create_key_pair ? aws_key_pair.this[0].fingerprint : null
}

# Storage Information
output "root_volume_id" {
  description = "ID of the root volume"
  value       = aws_instance.this.root_block_device[0].volume_id
}

output "additional_volume_ids" {
  description = "List of additional volume IDs"
  value       = aws_ebs_volume.additional[*].id
}

output "additional_volume_attachments" {
  description = "Map of additional volume attachments"
  value = {
    for i, volume in aws_ebs_volume.additional :
    volume.id => {
      device_name = aws_volume_attachment.additional[i].device_name
      volume_id   = volume.id
      instance_id = aws_instance.this.id
    }
  }
}

# Custom Policy Information
output "custom_policy_arns" {
  description = "List of custom policy ARNs (if created by this module)"
  value       = var.create_iam_role ? aws_iam_policy.custom_policies[*].arn : []
}

output "custom_policy_names" {
  description = "List of custom policy names (if created by this module)"
  value       = var.create_iam_role ? aws_iam_policy.custom_policies[*].name : []
}

# Connection Information
output "connection_info" {
  description = "Connection information for the EC2 instance"
  value = {
    instance_id   = aws_instance.this.id
    public_ip     = aws_instance.this.public_ip
    private_ip    = aws_instance.this.private_ip
    public_dns    = aws_instance.this.public_dns
    private_dns   = aws_instance.this.private_dns
    key_pair_name = var.create_key_pair ? aws_key_pair.this[0].key_name : var.existing_key_pair_name
    ssh_command   = "ssh -i ${var.create_key_pair ? aws_key_pair.this[0].key_name : var.existing_key_pair_name}.pem ec2-user@${aws_instance.this.public_ip}"
  }
}

# Summary Output
output "instance_summary" {
  description = "Summary of the EC2 instance configuration"
  value = {
    name                 = local.instance_name
    id                   = aws_instance.this.id
    type                 = aws_instance.this.instance_type
    ami                  = aws_instance.this.ami
    state                = aws_instance.this.instance_state
    public_ip            = aws_instance.this.public_ip
    private_ip           = aws_instance.this.private_ip
    availability_zone    = aws_instance.this.availability_zone
    security_groups      = aws_instance.this.vpc_security_group_ids
    iam_instance_profile = var.create_iam_role ? aws_iam_instance_profile.this[0].name : var.existing_iam_instance_profile
    key_pair             = var.create_key_pair ? aws_key_pair.this[0].key_name : var.existing_key_pair_name
    root_volume_size     = var.root_volume_size
    additional_volumes   = length(var.additional_volumes)
    tags                 = aws_instance.this.tags
  }
}
