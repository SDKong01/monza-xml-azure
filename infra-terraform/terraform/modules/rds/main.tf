# Data source to get the latest PostgreSQL engine version
data "aws_rds_engine_version" "postgresql" {
  engine = var.db_engine
}

# DB Subnet Group for RDS instance
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-${var.db_instance_identifier}-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-${var.db_instance_identifier}-subnet-group"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "rds"
  })
}

# Security Group for RDS instance
resource "aws_security_group" "db" {
  name_prefix = "${var.project_name}-${var.environment}-${var.db_instance_identifier}-sg-"
  vpc_id      = var.vpc_id
  description = "Security group for ${var.project_name} ${var.environment} PostgreSQL database"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-${var.db_instance_identifier}-sg"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "rds"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rule: Allow inbound PostgreSQL traffic from Keycloak app
resource "aws_vpc_security_group_ingress_rule" "db_ingress" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = var.keycloak_app_security_group_id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "Allow PostgreSQL access from Keycloak application"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-db-ingress-from-keycloak"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "rds"
  })
}

# Security Group Rule: Allow all outbound traffic (for maintenance, updates, etc.)
resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-db-egress-all"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "rds"
  })
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "main" {
  # Basic Configuration
  identifier     = "${var.project_name}-${var.environment}-${var.db_instance_identifier}"
  engine         = var.db_engine
  engine_version = data.aws_rds_engine_version.postgresql.version
  instance_class = var.db_instance_class

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  # Storage Configuration
  allocated_storage     = var.db_allocated_storage
  storage_type          = var.db_storage_type
  storage_encrypted     = var.storage_encrypted
  max_allocated_storage = var.db_allocated_storage * 2 # Enable storage autoscaling up to 2x initial size

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"         # UTC - Low traffic time
  maintenance_window      = "sun:04:00-sun:05:00" # UTC - After backup window

  # High Availability & Monitoring
  multi_az                        = var.multi_az
  monitoring_interval             = var.monitoring_interval
  enabled_cloudwatch_logs_exports = var.monitoring_interval > 0 ? ["postgresql"] : []

  # Lifecycle Management
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-${var.db_instance_identifier}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection       = var.deletion_protection

  # Performance & Maintenance
  auto_minor_version_upgrade = true
  apply_immediately          = var.environment == "dev" ? true : false

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-${var.db_instance_identifier}"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Module      = "rds"
    Engine      = var.db_engine
    Purpose     = "Keycloak Authentication Database"
  })

  depends_on = [
    aws_db_subnet_group.main,
    aws_security_group.db
  ]
}
