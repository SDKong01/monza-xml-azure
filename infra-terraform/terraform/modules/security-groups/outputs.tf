# ALB Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "alb_security_group_arn" {
  description = "ARN of the ALB security group"
  value       = aws_security_group.alb.arn
}

output "alb_security_group_name" {
  description = "Name of the ALB security group"
  value       = aws_security_group.alb.name
}

# Web Security Group Outputs
output "web_security_group_id" {
  description = "ID of the web tier security group"
  value       = aws_security_group.web.id
}

output "web_security_group_arn" {
  description = "ARN of the web tier security group"
  value       = aws_security_group.web.arn
}

output "web_security_group_name" {
  description = "Name of the web tier security group"
  value       = aws_security_group.web.name
}

# Database Security Group Outputs
output "db_security_group_id" {
  description = "ID of the database security group"
  value       = aws_security_group.db.id
}

output "db_security_group_arn" {
  description = "ARN of the database security group"
  value       = aws_security_group.db.arn
}

output "db_security_group_name" {
  description = "Name of the database security group"
  value       = aws_security_group.db.name
}

# Convenience Outputs
output "security_group_ids" {
  description = "Map of all security group IDs"
  value = {
    alb = aws_security_group.alb.id
    web = aws_security_group.web.id
    db  = aws_security_group.db.id
  }
}

output "security_group_arns" {
  description = "Map of all security group ARNs"
  value = {
    alb = aws_security_group.alb.arn
    web = aws_security_group.web.arn
    db  = aws_security_group.db.arn
  }
}
