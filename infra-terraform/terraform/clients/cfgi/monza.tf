# =============================================================================
# CFGI CLIENT - MONZA PRODUCT INFRASTRUCTURE
# =============================================================================
#
# Monza Product Stack:
#   - EC2 instance for ClickHouse and Airflow
#   - Security group configuration
#   - IAM instance profile
#   - Bootstrap script for service deployment
#
# Deployment Order:
#   1. CFGI-010: Create ec2-monza module
#   2. CFGI-011: Create Monza bootstrap script
#   3. CFGI-012: Deploy Monza EC2 instance
#
# Configuration Status: PLACEHOLDER - AWAITING CLIENT SPECIFICATIONS
#
# Required Specifications:
#   - EC2 instance type (e.g., m5.xlarge, c5.2xlarge)
#   - Root volume size and type
#   - Additional data volumes for ClickHouse and Airflow
#   - ClickHouse configuration (users, databases, retention policies)
#   - Airflow configuration (DAGs, connections, variables)
#   - Networking preferences (public vs private subnet)
#
# =============================================================================

# =============================================================================
# MONZA EC2 INSTANCE (CFGI-012)
# =============================================================================
# 
# EC2 instance hosting ClickHouse and Airflow services for data infrastructure
# 
# Uncomment and configure once client provides specifications:
#
# module "monza" {
#   source = "../../modules/ec2-monza"
#   
#   # Project Configuration
#   project_name = local.project_name
#   environment  = local.environment
#   
#   # Instance Configuration
#   instance_type = "m5.xlarge"  # TODO: Specify based on workload requirements
#   ami_id        = "ami-0ea3c35c5c3284d82"  # Ubuntu 22.04 LTS us-east-2
#   
#   # Network Configuration
#   vpc_id                      = module.vpc.vpc_id
#   subnet_id                   = module.vpc.public_subnet_ids[0]  # Or private subnet
#   associate_public_ip_address = true  # Set to false for private subnet deployment
#   app_runner_security_group_id = module.kimball_backend.vpc_connector_security_group_id
#   
#   # Security Configuration
#   ssh_trusted_ip_ranges = local.trusted_ip_ranges
#   
#   # Bootstrap Configuration
#   bootstrap_script_path = "../../scripts/deploy_monza_bootstrap.sh.tpl"
#   
#   # Storage Configuration
#   root_volume_size      = 50   # TODO: Determine based on data volume
#   root_volume_type      = "gp3"
#   root_volume_encrypted = true
#   
#   # Additional data volumes for ClickHouse and Airflow storage
#   # additional_volumes = [
#   #   {
#   #     device_name = "/dev/sdf"
#   #     volume_size = 100
#   #     volume_type = "gp3"
#   #     encrypted   = true
#   #     mount_point = "/var/lib/clickhouse"
#   #   },
#   #   {
#   #     device_name = "/dev/sdg"
#   #     volume_size = 50
#   #     volume_type = "gp3"
#   #     encrypted   = true
#   #     mount_point = "/var/lib/airflow"
#   #   }
#   # ]
#   
#   # ClickHouse Configuration (TODO: Define based on client requirements)
#   # clickhouse_config = {
#   #   users          = ["default", "app_user"]
#   #   databases      = ["analytics", "logs"]
#   #   max_memory     = "8GB"
#   #   retention_days = 30
#   # }
#   
#   # Airflow Configuration (TODO: Define based on client requirements)
#   # airflow_config = {
#   #   executor      = "LocalExecutor"
#   #   parallelism   = 32
#   #   dag_directory = "/opt/airflow/dags"
#   # }
#   
#   # Monitoring Configuration
#   enable_detailed_monitoring = true
#   
#   # SSH Key Pair
#   # create_key_pair     = true
#   # key_pair_name       = "monza-cfgi-key"
#   # key_pair_public_key = var.monza_ssh_public_key
#   
#   # Tags
#   additional_tags = merge(local.common_tags, {
#     Purpose     = "Data Infrastructure - ClickHouse and Airflow"
#     Application = "Monza"
#     Component   = "Data Platform"
#   })
# }

# =============================================================================
# OUTPUTS (CFGI-012)
# =============================================================================
# 
# Uncomment after Monza deployment to expose instance details
#
# output "monza_instance_id" {
#   description = "ID of the Monza EC2 instance"
#   value       = module.monza.instance_id
# }
#
# output "monza_private_ip" {
#   description = "Private IP address for Kimball backend connection"
#   value       = module.monza.private_ip
# }
#
# output "monza_public_ip" {
#   description = "Public IP address for SSH access"
#   value       = module.monza.public_ip
# }
#
# output "monza_security_group_id" {
#   description = "Security group ID for Monza EC2 instance"
#   value       = module.monza.security_group_id
# }

# =============================================================================
# NOTES
# =============================================================================
# 
# 1. The ec2-monza module needs to be created first (CFGI-010)
# 2. The Monza bootstrap script needs to be created (CFGI-011)
# 3. Update Kimball backend environment variables with Monza IP after deployment
# 4. Ensure App Runner VPC connector security group allows egress to Monza
# 5. Configure ClickHouse users and databases via bootstrap script
# 6. Setup Airflow connections and variables post-deployment
#
# =============================================================================
