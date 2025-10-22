# ===================================
# ElastiCache Cluster Outputs (Non-Cluster Mode)
# ===================================

output "cluster_id" {
  description = "ID of the ElastiCache cluster"
  value       = var.cluster_mode_enabled ? null : try(aws_elasticache_cluster.this[0].cluster_id, null)
}

output "cluster_arn" {
  description = "ARN of the ElastiCache cluster or replication group"
  value       = (var.cluster_mode_enabled || var.transit_encryption_enabled) ? try(aws_elasticache_replication_group.this[0].arn, null) : try(aws_elasticache_cluster.this[0].arn, null)
}

output "cluster_address" {
  description = "DNS name of the cache cluster without port (Memcached only)"
  value       = var.cluster_mode_enabled ? null : try(aws_elasticache_cluster.this[0].cluster_address, null)
}

output "cluster_cache_nodes" {
  description = "List of node objects including id, address, port, and availability_zone"
  value       = var.cluster_mode_enabled ? null : try(aws_elasticache_cluster.this[0].cache_nodes, [])
}

output "cluster_configuration_endpoint" {
  description = "Configuration endpoint to allow host discovery (Memcached only)"
  value       = var.cluster_mode_enabled ? null : try(aws_elasticache_cluster.this[0].configuration_endpoint, null)
}

output "cluster_engine_version_actual" {
  description = "Running version of the cache engine"
  value       = var.cluster_mode_enabled ? null : try(aws_elasticache_cluster.this[0].engine_version_actual, null)
}

# ===================================
# ElastiCache Replication Group Outputs (Cluster Mode)
# ===================================

output "replication_group_id" {
  description = "ID of the ElastiCache replication group"
  value       = var.cluster_mode_enabled ? try(aws_elasticache_replication_group.this[0].id, null) : null
}

output "replication_group_arn" {
  description = "ARN of the ElastiCache replication group"
  value       = var.cluster_mode_enabled ? try(aws_elasticache_replication_group.this[0].arn, null) : null
}

output "replication_group_configuration_endpoint_address" {
  description = "Address of the replication group configuration endpoint when cluster mode is enabled"
  value       = var.cluster_mode_enabled ? try(aws_elasticache_replication_group.this[0].configuration_endpoint_address, null) : null
}

output "replication_group_primary_endpoint_address" {
  description = "Address of the endpoint for the primary node in the replication group"
  value       = (var.cluster_mode_enabled || var.transit_encryption_enabled) ? try(aws_elasticache_replication_group.this[0].primary_endpoint_address, null) : null
}

output "replication_group_reader_endpoint_address" {
  description = "Address of the endpoint for the reader node in the replication group"
  value       = var.cluster_mode_enabled ? try(aws_elasticache_replication_group.this[0].reader_endpoint_address, null) : null
}

output "replication_group_member_clusters" {
  description = "Identifiers of all nodes that are part of this replication group"
  value       = var.cluster_mode_enabled ? try(aws_elasticache_replication_group.this[0].member_clusters, []) : null
}

output "replication_group_engine_version_actual" {
  description = "Running version of the cache engine for replication group"
  value       = var.cluster_mode_enabled ? try(aws_elasticache_replication_group.this[0].engine_version_actual, null) : null
}

# ===================================
# Common Outputs (Both Modes)
# ===================================

output "primary_endpoint_address" {
  description = "Primary endpoint address for connecting to the cache"
  value = (var.cluster_mode_enabled || var.transit_encryption_enabled) ? (
    var.engine == "redis" ? try(aws_elasticache_replication_group.this[0].primary_endpoint_address, null) :
    try(aws_elasticache_replication_group.this[0].configuration_endpoint_address, null)
    ) : (
    var.engine == "redis" ? try("${aws_elasticache_cluster.this[0].cache_nodes[0].address}", null) :
    try(aws_elasticache_cluster.this[0].cluster_address, null)
  )
}

output "port" {
  description = "Port number of the cache endpoint"
  value       = var.port
}

output "engine" {
  description = "Cache engine"
  value       = var.engine
}

output "engine_version" {
  description = "Cache engine version"
  value       = var.engine_version
}

# ===================================
# Infrastructure Outputs
# ===================================

output "security_group_id" {
  description = "ID of the security group created for the cache cluster"
  value       = aws_security_group.this.id
}

output "security_group_arn" {
  description = "ARN of the security group created for the cache cluster"
  value       = aws_security_group.this.arn
}

output "subnet_group_name" {
  description = "Name of the ElastiCache subnet group"
  value       = aws_elasticache_subnet_group.this.name
}

output "parameter_group_id" {
  description = "ID of the ElastiCache parameter group"
  value       = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].id : null
}

output "parameter_group_arn" {
  description = "ARN of the ElastiCache parameter group"
  value       = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].arn : null
}

# ===================================
# Connection Information
# ===================================

output "connection_info" {
  description = "Connection information for the ElastiCache cluster"
  value = {
    endpoint = var.cluster_mode_enabled ? (
      var.engine == "redis" ? try(aws_elasticache_replication_group.this[0].primary_endpoint_address, null) :
      try(aws_elasticache_replication_group.this[0].configuration_endpoint_address, null)
      ) : (
      var.engine == "redis" ? try("${aws_elasticache_cluster.this[0].cache_nodes[0].address}", null) :
      try(aws_elasticache_cluster.this[0].cluster_address, null)
    )
    port               = var.port
    engine             = var.engine
    cluster_mode       = var.cluster_mode_enabled
    encryption_at_rest = var.at_rest_encryption_enabled
    encryption_transit = var.transit_encryption_enabled
  }
}

# ===================================
# Summary Output
# ===================================

output "elasticache_summary" {
  description = "Summary of ElastiCache cluster configuration"
  value = {
    cluster_id     = local.cluster_id
    engine         = var.engine
    engine_version = var.engine_version
    node_type      = var.node_type
    cluster_mode   = var.cluster_mode_enabled
    multi_az       = var.multi_az_enabled
    endpoint = var.cluster_mode_enabled ? (
      var.engine == "redis" ? try(aws_elasticache_replication_group.this[0].primary_endpoint_address, null) :
      try(aws_elasticache_replication_group.this[0].configuration_endpoint_address, null)
      ) : (
      var.engine == "redis" ? try("${aws_elasticache_cluster.this[0].cache_nodes[0].address}", null) :
      try(aws_elasticache_cluster.this[0].cluster_address, null)
    )
    port                 = var.port
    security_group_id    = aws_security_group.this.id
    subnet_group_name    = aws_elasticache_subnet_group.this.name
    parameter_group_name = local.parameter_group_name
  }
}
