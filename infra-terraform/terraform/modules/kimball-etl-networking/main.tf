# Local values for consistent resource naming and tagging
locals {
  name_prefix = "${var.project_name}-${var.environment}-kimball-etl"
  common_tags = merge(
    var.common_tags,
    var.additional_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "kimball-etl-networking"
    }
  )
  external_access_cidr = var.allow_all_external_access ? "0.0.0.0/0" : var.trusted_ip_ranges[0]
}

# ETL Public Subnet
resource "aws_subnet" "etl_public" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.etl_public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet-a"
    Tier = "Public"
  })
}

# ETL Private Subnet
resource "aws_subnet" "etl_private" {
  vpc_id            = var.vpc_id
  cidr_block        = var.etl_private_subnet_cidr
  availability_zone = var.availability_zone

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-private-subnet-a"
    Tier = "Private"
  })
}

# Route Table Associations
resource "aws_route_table_association" "etl_public" {
  subnet_id      = aws_subnet.etl_public.id
  route_table_id = var.public_route_table_id

  depends_on = [aws_subnet.etl_public]
}

resource "aws_route_table_association" "etl_private" {
  subnet_id      = aws_subnet.etl_private.id
  route_table_id = var.private_route_table_id

  depends_on = [aws_subnet.etl_private]
}

# ETL External Services Security Group
resource "aws_security_group" "etl_external" {
  name_prefix = "${local.name_prefix}-external-"
  description = "Security group for ETL external-facing services (Airflow, MinIO Console, Hive)"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-external-sg"
    Tier = "External"
  })
}

# ETL Internal Services Security Group
resource "aws_security_group" "etl_internal" {
  name_prefix = "${local.name_prefix}-internal-"
  description = "Security group for ETL internal cluster communication (Spark)"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-internal-sg"
    Tier = "Internal"
  })
}

# ETL Database Services Security Group
resource "aws_security_group" "etl_database" {
  name_prefix = "${local.name_prefix}-db-"
  description = "Security group for ETL databases and storage services"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-db-sg"
    Tier = "Database"
  })
}

# SSH Access
resource "aws_vpc_security_group_ingress_rule" "etl_ssh" {
  count = length(var.trusted_ip_ranges) > 0 ? 1 : 0

  security_group_id = aws_security_group.etl_external.id
  description       = "SSH access for ETL server administration"

  from_port   = var.etl_external_ports.ssh
  to_port     = var.etl_external_ports.ssh
  ip_protocol = "tcp"
  cidr_ipv4   = var.trusted_ip_ranges[0]

  tags = {
    Name = "ETL SSH Access"
  }
}

# HTTP Traffic
resource "aws_vpc_security_group_ingress_rule" "etl_http" {
  security_group_id = aws_security_group.etl_external.id
  description       = "HTTP traffic for ETL web interfaces"

  from_port   = var.etl_external_ports.http
  to_port     = var.etl_external_ports.http
  ip_protocol = "tcp"
  cidr_ipv4   = local.external_access_cidr

  tags = {
    Name = "ETL HTTP Access"
  }
}

resource "aws_vpc_security_group_ingress_rule" "etl_https" {
  security_group_id = aws_security_group.etl_external.id
  description       = "HTTPS traffic for ETL web interfaces"

  from_port   = var.etl_external_ports.https
  to_port     = var.etl_external_ports.https
  ip_protocol = "tcp"
  cidr_ipv4   = local.external_access_cidr

  tags = {
    Name = "ETL HTTPS Access"
  }
}

# Airflow
resource "aws_vpc_security_group_ingress_rule" "etl_airflow" {
  security_group_id = aws_security_group.etl_external.id
  description       = "Airflow web interface access"

  from_port   = var.etl_external_ports.airflow
  to_port     = var.etl_external_ports.airflow
  ip_protocol = "tcp"
  cidr_ipv4   = local.external_access_cidr

  tags = {
    Name = "ETL Airflow UI"
  }
}

# MinIO Console
resource "aws_vpc_security_group_ingress_rule" "etl_minio_console" {
  security_group_id = aws_security_group.etl_external.id
  description       = "MinIO web management console"

  from_port   = var.etl_external_ports.minio_console
  to_port     = var.etl_external_ports.minio_console
  ip_protocol = "tcp"
  cidr_ipv4   = local.external_access_cidr

  tags = {
    Name = "ETL MinIO Console"
  }
}

# Hive Metastore
resource "aws_vpc_security_group_ingress_rule" "etl_hive_metastore" {
  security_group_id = aws_security_group.etl_external.id
  description       = "Hive Metastore service access"

  from_port   = var.etl_external_ports.hive_metastore
  to_port     = var.etl_external_ports.hive_metastore
  ip_protocol = "tcp"
  cidr_ipv4   = local.external_access_cidr

  tags = {
    Name = "ETL Hive Metastore"
  }
}

# HiveServer2
resource "aws_vpc_security_group_ingress_rule" "etl_hive_server2" {
  security_group_id = aws_security_group.etl_external.id
  description       = "HiveServer2 SQL query service"

  from_port   = var.etl_external_ports.hive_server2
  to_port     = var.etl_external_ports.hive_server2
  ip_protocol = "tcp"
  cidr_ipv4   = local.external_access_cidr

  tags = {
    Name = "ETL HiveServer2"
  }
}

# Redis
resource "aws_vpc_security_group_ingress_rule" "etl_redis" {
  security_group_id = aws_security_group.etl_internal.id
  description       = "Redis broker for Airflow tasks"

  from_port   = var.etl_internal_ports.redis
  to_port     = var.etl_internal_ports.redis
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "ETL Redis Internal"
  }
}

# Spark Master
resource "aws_vpc_security_group_ingress_rule" "etl_spark_master" {
  security_group_id = aws_security_group.etl_internal.id
  description       = "Spark Master coordination port"

  from_port   = var.etl_internal_ports.spark_master
  to_port     = var.etl_internal_ports.spark_master
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "ETL Spark Master"
  }
}

# Spark Master UI
resource "aws_vpc_security_group_ingress_rule" "etl_spark_master_ui" {
  security_group_id = aws_security_group.etl_internal.id
  description       = "Spark Master monitoring UI"

  from_port   = var.etl_internal_ports.spark_master_ui
  to_port     = var.etl_internal_ports.spark_master_ui
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "ETL Spark Master UI"
  }
}

# Spark Worker UI
resource "aws_vpc_security_group_ingress_rule" "etl_spark_worker_ui" {
  security_group_id = aws_security_group.etl_internal.id
  description       = "Spark Worker monitoring UI"

  from_port   = var.etl_internal_ports.spark_worker_ui
  to_port     = var.etl_internal_ports.spark_worker_ui
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "ETL Spark Worker UI"
  }
}

# Spark Executors
resource "aws_vpc_security_group_ingress_rule" "etl_spark_executors" {
  security_group_id = aws_security_group.etl_internal.id
  description       = "Spark dynamic executor ports"

  from_port   = var.etl_internal_ports.spark_executor_start
  to_port     = var.etl_internal_ports.spark_executor_end
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "ETL Spark Executors"
  }
}

# MySQL
resource "aws_vpc_security_group_ingress_rule" "etl_mysql" {
  count = length(var.trusted_ip_ranges) > 0 ? 1 : 0

  security_group_id = aws_security_group.etl_database.id
  description       = "MySQL database access (restricted)"

  from_port   = var.etl_database_ports.mysql
  to_port     = var.etl_database_ports.mysql
  ip_protocol = "tcp"
  cidr_ipv4   = var.trusted_ip_ranges[0]

  tags = {
    Name = "ETL MySQL Access"
  }
}

# MinIO API
resource "aws_vpc_security_group_ingress_rule" "etl_minio_api" {
  security_group_id = aws_security_group.etl_database.id
  description       = "MinIO S3 API internal access"

  from_port   = var.etl_external_ports.minio_api
  to_port     = var.etl_external_ports.minio_api
  ip_protocol = "tcp"
  cidr_ipv4   = var.vpc_cidr

  tags = {
    Name = "ETL MinIO API Internal"
  }
}

# Security Group Egress Rules
resource "aws_vpc_security_group_egress_rule" "etl_external_egress" {
  security_group_id = aws_security_group.etl_external.id
  description       = "All outbound traffic from ETL external services"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "ETL External All Outbound"
  }
}

resource "aws_vpc_security_group_egress_rule" "etl_internal_egress" {
  security_group_id = aws_security_group.etl_internal.id
  description       = "All outbound traffic from ETL internal services"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "ETL Internal All Outbound"
  }
}

resource "aws_vpc_security_group_egress_rule" "etl_database_egress" {
  security_group_id = aws_security_group.etl_database.id
  description       = "All outbound traffic from ETL database services"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "ETL Database All Outbound"
  }
}
