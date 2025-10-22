# ===================================
# Local Values
# ===================================

locals {
  cluster_id = var.cluster_id != null ? var.cluster_id : "${var.service_name}-redis-elasticache-${var.environment}"

  # Merge all tags
  common_tags = merge(
    var.common_tags,
    var.additional_tags,
    {
      Name      = local.cluster_id
      Module    = "elasticache"
      Service   = var.service_name
      Component = "cache-cluster"
      Engine    = var.engine
      ManagedBy = "Terraform"
    }
  )

  # Parameter group name
  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : "${var.parameter_group_family}.cluster.on"

  # Subnet group name
  subnet_group_name = "${local.cluster_id}-subnet-group"
}

# ===================================
# ElastiCache Subnet Group
# ===================================

resource "aws_elasticache_subnet_group" "this" {
  name       = local.subnet_group_name
  subnet_ids = var.subnet_ids

  tags = merge(local.common_tags, {
    Name      = local.subnet_group_name
    Component = "subnet-group"
  })
}

# ===================================
# ElastiCache Parameter Group
# ===================================

resource "aws_elasticache_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  family = var.parameter_group_family
  name   = "${local.cluster_id}-params"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${local.cluster_id}-params"
    Component = "parameter-group"
    Family    = var.parameter_group_family
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================
# ElastiCache Security Group
# ===================================

resource "aws_security_group" "this" {
  name_prefix = "${local.cluster_id}-"
  description = "Security group for ${local.cluster_id} ElastiCache cluster"
  vpc_id      = var.vpc_id

  # Ingress rule for Redis/Memcached port from VPC
  ingress {
    description = "Cache access from VPC"
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  # Egress rule - allow all outbound
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${local.cluster_id}-sg"
    Component = "security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================
# Data Sources
# ===================================

data "aws_vpc" "selected" {
  id = var.vpc_id
}

# ===================================
# ElastiCache Cluster (Non-Cluster Mode)
# ===================================

resource "aws_elasticache_cluster" "this" {
  count = var.cluster_mode_enabled || var.transit_encryption_enabled ? 0 : 1

  cluster_id           = local.cluster_id
  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  parameter_group_name = local.parameter_group_name
  port                 = var.port
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = concat([aws_security_group.this.id], var.security_group_ids)

  # Maintenance and updates
  maintenance_window         = var.maintenance_window
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Snapshots (Redis only)
  snapshot_retention_limit  = var.engine == "redis" ? var.snapshot_retention_limit : null
  snapshot_window           = var.engine == "redis" ? var.snapshot_window : null
  final_snapshot_identifier = var.engine == "redis" ? var.final_snapshot_identifier : null

  tags = local.common_tags

  depends_on = [
    aws_elasticache_subnet_group.this,
    aws_elasticache_parameter_group.this
  ]
}

# ===================================
# ElastiCache Replication Group (Cluster Mode)
# ===================================

resource "aws_elasticache_replication_group" "this" {
  count = var.cluster_mode_enabled || var.transit_encryption_enabled ? 1 : 0

  replication_group_id = "${local.cluster_id}-rg"
  description          = var.description
  engine               = var.engine
  engine_version       = var.engine_version
  node_type            = var.node_type
  parameter_group_name = local.parameter_group_name
  port                 = var.port
  subnet_group_name    = aws_elasticache_subnet_group.this.name
  security_group_ids   = concat([aws_security_group.this.id], var.security_group_ids)

  # Cluster mode configuration (only for cluster mode enabled)
  num_node_groups         = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group = var.cluster_mode_enabled ? var.replicas_per_node_group : null

  # Non-cluster mode configuration (for transit encryption support)
  num_cache_clusters = var.cluster_mode_enabled ? null : var.num_cache_nodes

  # High availability
  automatic_failover_enabled = var.automatic_failover_enabled
  multi_az_enabled           = var.multi_az_enabled

  # Security
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.auth_token

  # Maintenance and updates
  maintenance_window         = var.maintenance_window
  apply_immediately          = var.apply_immediately
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # Snapshots (Redis only)
  snapshot_retention_limit  = var.engine == "redis" ? var.snapshot_retention_limit : null
  snapshot_window           = var.engine == "redis" ? var.snapshot_window : null
  final_snapshot_identifier = var.engine == "redis" ? var.final_snapshot_identifier : null

  tags = local.common_tags

  depends_on = [
    aws_elasticache_subnet_group.this,
    aws_elasticache_parameter_group.this
  ]
}
