# Subnet Outputs

output "etl_public_subnet_id" {
  description = "ID of the ETL public subnet"
  value       = aws_subnet.etl_public.id
}

output "etl_public_subnet_arn" {
  description = "ARN of the ETL public subnet"
  value       = aws_subnet.etl_public.arn
}

output "etl_public_subnet_cidr" {
  description = "CIDR block of the ETL public subnet"
  value       = aws_subnet.etl_public.cidr_block
}

output "etl_public_subnet_az" {
  description = "Availability zone of the ETL public subnet"
  value       = aws_subnet.etl_public.availability_zone
}

output "etl_private_subnet_id" {
  description = "ID of the ETL private subnet"
  value       = aws_subnet.etl_private.id
}

output "etl_private_subnet_arn" {
  description = "ARN of the ETL private subnet"
  value       = aws_subnet.etl_private.arn
}

output "etl_private_subnet_cidr" {
  description = "CIDR block of the ETL private subnet"
  value       = aws_subnet.etl_private.cidr_block
}

output "etl_private_subnet_az" {
  description = "Availability zone of the ETL private subnet"
  value       = aws_subnet.etl_private.availability_zone
}

# Security Group Outputs

output "etl_external_security_group_id" {
  description = "ID of the ETL external services security group"
  value       = aws_security_group.etl_external.id
}

output "etl_external_security_group_arn" {
  description = "ARN of the ETL external services security group"
  value       = aws_security_group.etl_external.arn
}

output "etl_external_security_group_name" {
  description = "Name of the ETL external services security group"
  value       = aws_security_group.etl_external.name
}

output "etl_internal_security_group_id" {
  description = "ID of the ETL internal services security group"
  value       = aws_security_group.etl_internal.id
}

output "etl_internal_security_group_arn" {
  description = "ARN of the ETL internal services security group"
  value       = aws_security_group.etl_internal.arn
}

output "etl_internal_security_group_name" {
  description = "Name of the ETL internal services security group"
  value       = aws_security_group.etl_internal.name
}

output "etl_database_security_group_id" {
  description = "ID of the ETL database services security group"
  value       = aws_security_group.etl_database.id
}

output "etl_database_security_group_arn" {
  description = "ARN of the ETL database services security group"
  value       = aws_security_group.etl_database.arn
}

output "etl_database_security_group_name" {
  description = "Name of the ETL database services security group"
  value       = aws_security_group.etl_database.name
}

# Route Table Association Outputs

output "etl_public_route_association_id" {
  description = "ID of the ETL public subnet route table association"
  value       = aws_route_table_association.etl_public.id
}

output "etl_private_route_association_id" {
  description = "ID of the ETL private subnet route table association"
  value       = aws_route_table_association.etl_private.id
}

# Grouped Outputs

output "etl_subnet_ids" {
  description = "Map of ETL subnet IDs"
  value = {
    public  = aws_subnet.etl_public.id
    private = aws_subnet.etl_private.id
  }
}

output "etl_subnet_cidrs" {
  description = "Map of ETL subnet CIDR blocks"
  value = {
    public  = aws_subnet.etl_public.cidr_block
    private = aws_subnet.etl_private.cidr_block
  }
}

output "etl_security_group_ids" {
  description = "Map of ETL security group IDs"
  value = {
    external = aws_security_group.etl_external.id
    internal = aws_security_group.etl_internal.id
    database = aws_security_group.etl_database.id
  }
}

output "etl_security_group_names" {
  description = "Map of ETL security group names"
  value = {
    external = aws_security_group.etl_external.name
    internal = aws_security_group.etl_internal.name
    database = aws_security_group.etl_database.name
  }
}

# Summary Outputs

output "etl_network_summary" {
  description = "Summary of ETL networking resources created"
  value = {
    vpc_id            = var.vpc_id
    availability_zone = var.availability_zone
    subnets = {
      public = {
        id   = aws_subnet.etl_public.id
        cidr = aws_subnet.etl_public.cidr_block
        name = aws_subnet.etl_public.tags["Name"]
      }
      private = {
        id   = aws_subnet.etl_private.id
        cidr = aws_subnet.etl_private.cidr_block
        name = aws_subnet.etl_private.tags["Name"]
      }
    }
    security_groups = {
      external = {
        id   = aws_security_group.etl_external.id
        name = aws_security_group.etl_external.name
      }
      internal = {
        id   = aws_security_group.etl_internal.id
        name = aws_security_group.etl_internal.name
      }
      database = {
        id   = aws_security_group.etl_database.id
        name = aws_security_group.etl_database.name
      }
    }
    resource_count = {
      subnets            = 2
      security_groups    = 3
      ingress_rules      = 13
      egress_rules       = 3
      route_associations = 2
    }
  }
}

# Deployment Information

output "deployment_info" {
  description = "ETL module deployment information"
  value = {
    module_name  = "kimball-etl-networking"
    deployed_at  = timestamp()
    environment  = var.environment
    project_name = var.project_name
    name_prefix  = "${var.project_name}-${var.environment}-kimball-etl"
    aws_region   = data.aws_region.current.name
  }
}

# Data source to get current AWS region
data "aws_region" "current" {}
