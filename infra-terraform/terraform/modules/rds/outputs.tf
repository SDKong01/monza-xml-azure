# RDS Instance Outputs
output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_identifier" {
  description = "The RDS instance identifier"
  value       = aws_db_instance.main.identifier
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = aws_db_instance.main.hosted_zone_id
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.main.port
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.main.status
}

output "db_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.main.engine
}

output "db_instance_engine_version" {
  description = "The running version of the database"
  value       = aws_db_instance.main.engine_version_actual
}

output "db_instance_class" {
  description = "The RDS instance class"
  value       = aws_db_instance.main.instance_class
}

output "db_instance_storage_type" {
  description = "The RDS instance storage type"
  value       = aws_db_instance.main.storage_type
}

output "db_instance_allocated_storage" {
  description = "The amount of allocated storage"
  value       = aws_db_instance.main.allocated_storage
}

output "db_instance_storage_encrypted" {
  description = "Whether the DB instance is encrypted"
  value       = aws_db_instance.main.storage_encrypted
}

output "db_instance_kms_key_id" {
  description = "The ARN of the KMS Key used to encrypt the DB instance"
  value       = aws_db_instance.main.kms_key_id
}

# Database Connection Information
output "db_name" {
  description = "The database name"
  value       = aws_db_instance.main.db_name
}

output "db_username" {
  description = "The master username for the database"
  value       = aws_db_instance.main.username
  sensitive   = true
}

# Network Configuration Outputs
output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = aws_db_subnet_group.main.id
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = aws_db_subnet_group.main.arn
}

output "db_security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.db.id
}

output "db_security_group_arn" {
  description = "The ARN of the security group"
  value       = aws_security_group.db.arn
}

# Backup and Maintenance Information
output "db_backup_retention_period" {
  description = "The backup retention period"
  value       = aws_db_instance.main.backup_retention_period
}

output "db_backup_window" {
  description = "The backup window"
  value       = aws_db_instance.main.backup_window
}

output "db_maintenance_window" {
  description = "The maintenance window"
  value       = aws_db_instance.main.maintenance_window
}

# Connection String (for application configuration)
output "db_connection_string" {
  description = "PostgreSQL connection string (without password)"
  value       = "postgresql://${aws_db_instance.main.username}@${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
  sensitive   = true
}

# JDBC URL (for Keycloak configuration)
output "db_jdbc_url" {
  description = "JDBC URL for PostgreSQL connection (for Keycloak)"
  value       = "jdbc:postgresql://${aws_db_instance.main.endpoint}:${aws_db_instance.main.port}/${aws_db_instance.main.db_name}"
}

# Summary output for easy reference
output "rds_summary" {
  description = "Summary of RDS instance configuration"
  value = {
    identifier     = aws_db_instance.main.identifier
    endpoint       = aws_db_instance.main.endpoint
    port           = aws_db_instance.main.port
    database_name  = aws_db_instance.main.db_name
    engine         = aws_db_instance.main.engine
    engine_version = aws_db_instance.main.engine_version_actual
    instance_class = aws_db_instance.main.instance_class
    storage_type   = aws_db_instance.main.storage_type
    storage_size   = aws_db_instance.main.allocated_storage
    encrypted      = aws_db_instance.main.storage_encrypted
    multi_az       = aws_db_instance.main.multi_az
    vpc_id         = var.vpc_id
    environment    = var.environment
  }
}
