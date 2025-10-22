# Kainam Infrastructure - DEV Environment Resource Mapping

## Overview
This document maps all AWS resources deployed in the **DEV environment** through Terraform infrastructure as code. All resources follow the naming convention: `kainam-dev-{service}-{type}` and are tagged with `Project: kainam`, `Environment: dev`, `ManagedBy: Terraform`.

---

## 🌐 VPC Module Resources

### Core VPC Infrastructure
| Service | Resource Name | Resource Type | ARN Pattern |
|---------|---------------|---------------|-------------|
| **VPC** | `kainam-dev-vpc` | `aws_vpc` | `arn:aws:ec2:us-east-2:ACCOUNT:vpc/vpc-*` |
| **Internet Gateway** | `kainam-dev-igw` | `aws_internet_gateway` | `arn:aws:ec2:us-east-2:ACCOUNT:internet-gateway/igw-*` |
| **NAT Gateway** | `kainam-dev-nat-gw` | `aws_nat_gateway` | `arn:aws:ec2:us-east-2:ACCOUNT:natgateway/nat-*` |
| **Elastic IP** | `kainam-dev-nat-eip` | `aws_eip` | `arn:aws:ec2:us-east-2:ACCOUNT:elastic-ip/eipalloc-*` |

**VPC Configuration:**
- **CIDR Block:** `10.0.0.0/16`
- **DNS Hostnames:** Enabled
- **DNS Support:** Enabled
- **Region:** `us-east-2`

### Subnets
| Service | Resource Name | Resource Type | CIDR Block | Availability Zone |
|---------|---------------|---------------|------------|-------------------|
| **Public Subnet A** | `kainam-dev-public-subnet-a` | `aws_subnet` | `10.0.1.0/24` | `us-east-2a` |
| **Public Subnet B** | `kainam-dev-public-subnet-b` | `aws_subnet` | `10.0.2.0/24` | `us-east-2b` |
| **Private Subnet A** | `kainam-dev-private-subnet-a` | `aws_subnet` | `10.0.101.0/24` | `us-east-2a` |
| **Private Subnet B** | `kainam-dev-private-subnet-b` | `aws_subnet` | `10.0.102.0/24` | `us-east-2b` |

### Route Tables & Associations
| Service | Resource Name | Resource Type | Purpose |
|---------|---------------|---------------|---------|
| **Public Route Table** | `kainam-dev-public-rt` | `aws_route_table` | Routes `0.0.0.0/0` → Internet Gateway |
| **Private Route Table** | `kainam-dev-private-rt` | `aws_route_table` | Routes `0.0.0.0/0` → NAT Gateway |
| **Public RT Associations** | N/A | `aws_route_table_association` | Associates public subnets to public RT |
| **Private RT Associations** | N/A | `aws_route_table_association` | Associates private subnets to private RT |

---

## 🔒 Security Groups Module Resources

### ALB Security Group
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **ALB Security Group** | `kainam-dev-alb-sg` | `aws_security_group` | Application Load Balancer security group |
| **HTTPS Ingress Rule** | `alb-https-ingress` | `aws_vpc_security_group_ingress_rule` | Allows HTTPS (443) from `0.0.0.0/0` |
| **ALB to Web Egress** | `alb-to-web-egress` | `aws_vpc_security_group_egress_rule` | Allows all traffic to Web SG |
| **ALB to Keycloak Egress** | `alb-to-keycloak` | `aws_vpc_security_group_egress_rule` | Allows HTTP (8080) to Keycloak SG (ISSUE-012 fix) |

### Web Tier Security Group
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **Web Security Group** | `kainam-dev-web-sg` | `aws_security_group` | Web/Application tier security group |
| **Web from ALB Ingress** | `web-from-alb-ingress` | `aws_vpc_security_group_ingress_rule` | Allows all traffic from ALB SG |
| **Web All Outbound** | `web-all-outbound-egress` | `aws_vpc_security_group_egress_rule` | Allows all outbound traffic |

**Note:** SSH access rules are **not created** in DEV environment due to empty `trusted_ip_ranges` configuration.

### Keycloak Security Group (Dedicated Authentication Tier)
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **Keycloak Security Group** | `kainam-keycloak-dev-sg` | `aws_security_group` | Dedicated security group for Keycloak authentication service |
| **Keycloak from ALB Ingress** | `keycloak-from-alb-ingress` | `aws_vpc_security_group_ingress_rule` | Allows HTTP (8080) from ALB SG |
| **Keycloak All Outbound** | `keycloak-all-outbound-egress` | `aws_vpc_security_group_egress_rule` | Allows all outbound traffic |

**Security Enhancement (2025-09-09):**
- **Service Isolation**: Keycloak now operates in a dedicated security group following least privilege principles
- **Direct ALB Connectivity**: ALB can directly reach Keycloak for health checks and request routing
- **ISSUE-012 Resolution**: Fixed ALB target group health check timeouts with dedicated security group rule

### Database Security Group
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **Database Security Group** | `kainam-dev-db-sg` | `aws_security_group` | Database tier security group |
| **DB from Web Ingress** | `db-from-web-ingress` | `aws_vpc_security_group_ingress_rule` | Allows PostgreSQL (5432) from Web SG |
| **DB All Outbound** | `db-all-outbound-egress` | `aws_vpc_security_group_egress_rule` | Allows all outbound traffic |

---

## 📊 Kimball ETL Networking Module Resources

### ETL Subnets
| Service | Resource Name | Resource Type | CIDR Block | Availability Zone |
|---------|---------------|---------------|------------|-------------------|
| **ETL Public Subnet** | `kainam-dev-kimball-etl-public-subnet-a` | `aws_subnet` | `10.0.3.0/24` | `us-east-2a` |
| **ETL Private Subnet** | `kainam-dev-kimball-etl-private-subnet-a` | `aws_subnet` | `10.0.103.0/24` | `us-east-2a` |

### ETL Route Table Associations
| Service | Resource Name | Resource Type | Purpose |
|---------|---------------|---------------|---------|
| **ETL Public RT Association** | N/A | `aws_route_table_association` | Associates ETL public subnet to main public RT |
| **ETL Private RT Association** | N/A | `aws_route_table_association` | Associates ETL private subnet to main private RT |

### ETL Security Groups
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **ETL External SG** | `kainam-dev-kimball-etl-external-sg` | `aws_security_group` | External ETL services (Airflow, MinIO, Hive) |
| **ETL Internal SG** | `kainam-dev-kimball-etl-internal-*` | `aws_security_group` | Internal ETL cluster communication (Spark) |
| **ETL Database SG** | `kainam-dev-kimball-etl-db-*` | `aws_security_group` | ETL databases and storage services |

### ETL Security Group Rules
| Service | Rule Name | Resource Type | Description |
|---------|-----------|---------------|-------------|
| **All Outbound** | `etl-all-outbound` | `aws_vpc_security_group_egress_rule` | Allows all outbound traffic |
| **Airflow Web** | `etl-airflow-web` | `aws_vpc_security_group_ingress_rule` | Airflow Web UI (8080) from `0.0.0.0/0` |
| **MinIO Console** | `etl-minio-console` | `aws_vpc_security_group_ingress_rule` | MinIO Console (9001) from `0.0.0.0/0` |
| **MinIO API** | `etl-minio-api` | `aws_vpc_security_group_ingress_rule` | MinIO API (9000) from `0.0.0.0/0` |
| **Hive Metastore** | `etl-hive-metastore` | `aws_vpc_security_group_ingress_rule` | Hive Metastore (9083) from `0.0.0.0/0` |
| **PostgreSQL** | `etl-postgresql` | `aws_vpc_security_group_ingress_rule` | PostgreSQL (5432) from `0.0.0.0/0` |
| **Spark Master** | `etl-spark-master` | `aws_vpc_security_group_ingress_rule` | Spark Master (7077) from VPC CIDR |
| **Spark UI** | `etl-spark-ui` | `aws_vpc_security_group_ingress_rule` | Spark Web UI (8080) from VPC CIDR |
| **Spark Worker** | `etl-spark-worker` | `aws_vpc_security_group_ingress_rule` | Spark Worker (7000-7100) from VPC CIDR |

**Note:** SSH access rules are **not created** in ETL security groups due to empty `trusted_ip_ranges` configuration.

## 🔐 Authentication ALB Module Resources

### Authentication Load Balancer
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **Authentication ALB** | `kainam-auth-dev-alb` | `aws_lb` | Internet-facing ALB for Keycloak authentication service |

**ALB Configuration:**
- **Scheme:** Internet-facing
- **Load Balancer Type:** Application
- **HTTP/2:** Enabled for performance
- **Invalid Header Filtering:** Enabled for security
- **Idle Timeout:** 60 seconds
- **Deletion Protection:** Disabled for DEV environment

---

## 🎯 Target Groups Module Resources

### Keycloak Target Group
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **Keycloak Target Group** | `kainam-keycloak-dev-tg` | `aws_lb_target_group` | Target group for Keycloak instances |

**Target Group Configuration:**
- **Protocol:** HTTP
- **Port:** 8080 (Keycloak internal port)
- **Target Type:** instance
- **VPC:** kainam-dev-vpc

**Health Check Configuration:**
- **Health Check Path:** `/health/ready`
- **Health Check Protocol:** HTTP
- **Healthy Threshold:** 3 consecutive successful checks
- **Unhealthy Threshold:** 2 consecutive failed checks
- **Timeout:** 5 seconds
- **Interval:** 30 seconds
- **Expected Response:** 200 OK
- **Connection Draining:** 30 seconds

**Note:** Target group is created but initially has no registered targets. EC2 instances will be registered when they are created.

## 📦 ECR Module Resources

### Multi-Service Container Registry Architecture

The ECR module supports multiple services with dedicated repositories for each application stack. All repositories share consistent security, lifecycle, and cost optimization policies.

### SENNA Container Repositories
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **API Repository** | `senna-api-ecr-dev` | `aws_ecr_repository` | Container registry for SENNA backend/API Docker images |
| **Frontend Repository** | `senna-front-ecr-dev` | `aws_ecr_repository` | Container registry for SENNA frontend Docker images |
| **Models Repository** | `senna-models-ecr-dev` | `aws_ecr_repository` | Container registry for SENNA ML models/Celery worker Docker images |
| **Keycloak Repository** | `keycloak-ecr-dev` | `aws_ecr_repository` | Container registry for Keycloak authentication service Docker images |

### Kainam Platform Container Repositories
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **Platform API Repository** | `kainam-platform-api-ecr-dev` | `aws_ecr_repository` | Container registry for Kainam Platform backend/API Docker images |
| **Platform Frontend Repository** | `kainam-platform-front-ecr-dev` | `aws_ecr_repository` | Container registry for Kainam Platform frontend Docker images |

**Repository Configuration:**
- **Image Tag Mutability**: MUTABLE (allows overwriting tags during development)
- **Image Scanning**: Enabled on push for security vulnerability detection
- **Encryption**: AES256 encryption at rest
- **Lifecycle Policy**: Keep last 10 tagged images (v* prefix), delete untagged images after 1 day

**Integration Features:**
- **GitHub Actions Support**: Optional repository policies for CI/CD push access
- **Multi-Environment**: Configurable for dev, uat, prod environments
- **Cost Optimization**: Automatic image cleanup via lifecycle policies

**SENNA Repository URLs:**
- API: `592172380963.dkr.ecr.us-east-2.amazonaws.com/senna-api-ecr-dev`
- Frontend: `592172380963.dkr.ecr.us-east-2.amazonaws.com/senna-front-ecr-dev`
- Models: `592172380963.dkr.ecr.us-east-2.amazonaws.com/senna-models-ecr-dev`
- Keycloak: `592172380963.dkr.ecr.us-east-2.amazonaws.com/keycloak-ecr-dev`

**Kainam Platform Repository URLs:**
- Platform API: `592172380963.dkr.ecr.us-east-2.amazonaws.com/kainam-platform-api-ecr-dev`
- Platform Frontend: `592172380963.dkr.ecr.us-east-2.amazonaws.com/kainam-platform-front-ecr-dev`

**Multi-Service Architecture Features:**
- **Service Isolation**: Each platform maintains separate ECR repositories with dedicated naming
- **Shared Infrastructure**: Common lifecycle policies, security settings, and CI/CD role integration
- **Cost Optimization**: Unified lifecycle management across all repositories
- **Future-Ready**: Prepared for additional services (UAT, Production) with consistent patterns

---

## 🗄️ ElastiCache Module Resources

### SENNA Redis Cluster
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **Redis Replication Group** | `senna-redis-elasticache-dev-rg` | `aws_elasticache_replication_group` | Redis replication group with SSL/TLS encryption and authentication |
| **Parameter Group** | `senna-redis-elasticache-dev-params` | `aws_elasticache_parameter_group` | Custom parameter group with optimized Redis settings |
| **Subnet Group** | `senna-redis-elasticache-dev-subnet-group` | `aws_elasticache_subnet_group` | Subnet group for ElastiCache cluster placement |
| **Security Group** | `senna-redis-elasticache-dev-sg` | `aws_security_group` | Security group controlling Redis cluster access |

**Cluster Configuration:**
- **Engine**: Redis 7.0
- **Node Type**: cache.t4g.small
- **Cluster Mode**: Disabled (replication group configuration)
- **Multi-AZ**: Disabled (development environment)
- **Port**: 6379 (standard Redis port)
- **Encryption**: At-rest enabled, transit encryption enabled with authentication
- **Authentication**: Enabled with secure auth token

**Network Configuration:**
- **VPC**: kainam-dev-vpc (vpc-0c864043de1e33fe8)
- **Subnets**: kainam-dev-private-subnet-a, kainam-dev-public-subnet-b
- **Security**: Access allowed from VPC CIDR (10.0.0.0/16) on port 6379
- **SSL/TLS**: Transit encryption enabled for secure client connections
- **Authentication**: Auth token required for Redis commands

**Parameter Group Settings:**
- **Family**: redis7
- **Max Memory Policy**: allkeys-lru (evict least recently used keys when memory limit reached)

**Operational Settings:**
- **Maintenance Window**: Sunday 05:00-09:00 UTC
- **Snapshot Window**: Daily 03:00-05:00 UTC
- **Snapshot Retention**: 5 days
- **Auto Minor Version Upgrade**: Enabled

**Connection Details:**
- **Primary Endpoint**: `senna-redis-elasticache-dev-rg.bq7cs9.use2.cache.amazonaws.com`
- **Port**: 6379 (standard Redis port)
- **Connection String**: `senna-redis-elasticache-dev-rg.bq7cs9.use2.cache.amazonaws.com:6379`
- **Access**: Available from any EC2 instance within VPC (10.0.0.0/16) with authentication
- **Auth Token**: Required for all Redis operations

---

## 💾 RDS Module Resources

### Keycloak PostgreSQL Database
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **RDS Instance** | `kainam-dev-keycloak-db` | `aws_db_instance` | PostgreSQL database instance for Keycloak |
| **Subnet Group** | `kainam-dev-keycloak-db-subnet-group` | `aws_db_subnet_group` | Subnet group for RDS instance placement in private subnets |
| **Security Group** | `kainam-dev-keycloak-db-sg` | `aws_security_group` | Security group controlling RDS instance access |
| **Ingress Rule** | `db-ingress-from-keycloak` | `aws_vpc_security_group_ingress_rule` | Allows PostgreSQL (5432) from Web SG |
| **Egress Rule** | `db-egress-all` | `aws_vpc_security_group_egress_rule` | Allows all outbound traffic |

**Database Configuration:**
- **Engine**: PostgreSQL 17.4
- **Instance Class**: db.t4g.micro
- **Storage**: 20GB GP3 (encrypted)
- **Multi-AZ**: Disabled (development environment)
- **Backup Retention**: 1 day
- **Deletion Protection**: Disabled for DEV environment

**Connection Details:**
- **Endpoint**: `kainam-dev-keycloak-db.cdik4w8gupyh.us-east-2.rds.amazonaws.com`
- **Port**: 5432
- **Database Name**: `kainam_keycloak_rds_pg_dev`
- **Username**: `keycloak_admin` (from Secrets Manager)

---

## 🔐 Secrets Manager Module Resources

### AWS Secrets Manager Integration
|| Service | Resource Name | Resource Type | Description |
||---------|---------------|---------------|-------------|
|| **Database Secret** | `keystone/dev/database` | `aws_secretsmanager_secret` | PostgreSQL database credentials for Keycloak |
|| **Keycloak Admin Secret** | `keystone/dev/keycloak_admin` | `aws_secretsmanager_secret` | Keycloak administrator credentials |
|| **Backend Client Secret** | `keystone/dev/backend_client_secret` | `aws_secretsmanager_secret` | SENNA backend client secret from Keycloak |

### Secret Configuration
|| Secret | Purpose | JSON Structure | Access Pattern |
||---------|---------|---------------|----------------|
|| **Database** | RDS PostgreSQL credentials | `{"username": "keycloak_admin", "password": "..."}` | EC2 instances via IAM role |
|| **Keycloak Admin** | Keycloak admin console access | `{"username": "admin-cli", "password": "..."}` | EC2 instances via IAM role |
|| **Backend Client** | SENNA backend OIDC client secret | `{"client_secret": "EkWnY7qgoYZbRWsW01KvbumkFSxgWm49"}` | App Runner and EC2 via IAM role |

**Security Features:**
- **Encryption**: All secrets encrypted at rest with AWS KMS
- **Access Control**: IAM policies restrict access to specific resources
- **Rotation**: Manual rotation supported (automatic rotation for future implementation)
- **Recovery**: 7-day recovery window for accidental deletion
- **Tagging**: Comprehensive resource tagging for cost allocation and management

**IAM Integration:**
- **EC2 Role**: `keystone-ec2-role` with read access to all project secrets
- **Policy**: `keystone-secrets-manager-read-policy` with least-privilege access
- **Instance Profile**: `keystone-ec2-profile` for seamless EC2 attachment

**Usage Examples:**
```bash
# Fetch database credentials
aws secretsmanager get-secret-value --secret-id "keystone/dev/database" --query SecretString --output text

# Fetch Keycloak admin credentials
aws secretsmanager get-secret-value --secret-id "keystone/dev/keycloak_admin" --query SecretString --output text

# Fetch backend client secret
aws secretsmanager get-secret-value --secret-id "keystone/dev/backend_client_secret" --query SecretString --output text
```

---

## 🔐 IAM Roles Module Resources

### SENNA Identity and Access Management
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **GitHub OIDC Provider** | `kainam-senna-dev-github-oidc-provider` | `aws_iam_openid_connect_provider` | GitHub Actions authentication provider for OIDC web identity |
| **GitHub Actions Role** | `kainam-senna-dev-github-actions-ecr-push` | `aws_iam_role` | IAM role for GitHub Actions to push Docker images to ECR repositories |
| **App Runner Access Role** | `kainam-senna-dev-app-runner-access` | `aws_iam_role` | IAM role for App Runner to pull images from ECR repositories |
| **App Runner Instance Role** | `kainam-senna-dev-app-runner-instance` | `aws_iam_role` | IAM role for App Runner service instances to access AWS resources at runtime |
| **EC2 Instance Role** | `kainam-senna-dev-ec2-instance` | `aws_iam_role` | General IAM role for EC2 instances with comprehensive AWS service access |
| **EC2 Worker Role** | `kainam-senna-dev-ec2-worker-role` | `aws_iam_role` | Specialized IAM role for SENNA EC2 worker instances with ECR read-only access |

### Instance Profiles
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **EC2 Instance Profile** | `kainam-senna-dev-ec2-instance-profile` | `aws_iam_instance_profile` | Instance profile for general EC2 instances |
| **EC2 Worker Profile** | `kainam-senna-dev-ec2-worker-profile` | `aws_iam_instance_profile` | Instance profile for SENNA EC2 worker instances |

### IAM Policies and Attachments
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **GitHub Actions ECR Policy** | `kainam-senna-dev-github-actions-ecr-push-policy` | `aws_iam_role_policy` | Inline policy for GitHub Actions ECR push/pull permissions |
| **App Runner Instance Policy** | `kainam-senna-dev-app-runner-instance-policy` | `aws_iam_role_policy` | Inline policy for App Runner CloudWatch logs and ElastiCache access |
| **EC2 Instance Policy** | `kainam-senna-dev-ec2-instance-policy` | `aws_iam_role_policy` | Inline policy for EC2 comprehensive AWS service access |
| **App Runner ECR Access Attachment** | N/A | `aws_iam_role_policy_attachment` | AWS managed policy attachment for App Runner ECR access |
| **EC2 Worker ECR Readonly Attachment** | N/A | `aws_iam_role_policy_attachment` | AWS managed policy attachment for EC2 worker ECR read-only access |

**Role Configuration:**
- **GitHub Actions Role**: OIDC web identity authentication with ECR push/pull permissions for repositories: `senna-api-ecr-dev`, `senna-front-ecr-dev`, `senna-models-ecr-dev`
- **App Runner Access Role**: Service-linked role for ECR image pulling during App Runner deployments
- **App Runner Instance Role**: Runtime permissions for CloudWatch logging and ElastiCache cluster access
- **EC2 Instance Role**: Comprehensive permissions including ECR access, ElastiCache access, CloudWatch logs, CloudWatch metrics, and SSM parameters
- **EC2 Worker Role**: Minimal permissions with ECR read-only access only (based on UAT `senna-ec2-worker-role-uat`)

**Security Features:**
- **Least Privilege Principle**: Each role has only the minimum permissions required for its specific function
- **Resource-Scoped Permissions**: ECR permissions limited to specific SENNA repositories
- **Environment Isolation**: All roles are environment-specific with `dev` environment tagging
- **Consistent Naming**: All resources follow `kainam-senna-dev-{resource-type}` pattern

---

## 🚀 App Runner Module Resources

### SENNA API Service
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **App Runner Service** | `kainam-senna-api-dev` | `aws_apprunner_service` | Managed container service for SENNA API backend |
| **VPC Connector** | `senna-ar-vpc-connector-dev` | `aws_apprunner_vpc_connector` | VPC integration for accessing internal resources (Redis, databases) |
| **Security Group** | `senna-net-sg-ar-egress-dev` | `aws_security_group` | Egress security group for App Runner service outbound traffic |
| **Egress Rule** | `app-runner-all-outbound` | `aws_vpc_security_group_egress_rule` | Allow all outbound traffic from App Runner service |

### SENNA Frontend Service
| Service | Resource Name | Resource Type | Description |
|---------|---------------|---------------|-------------|
| **App Runner Service** | `kainam-senna-front-dev` | `aws_apprunner_service` | Managed container service for SENNA frontend application |
| **Custom Domain Association** | `senna-dev.kainam.app` | `aws_apprunner_custom_domain_association` | Custom domain binding for frontend service |
| **Certificate Validation Record 1** | `_30b37806550f8f3f06e240713116efc1.senna-dev.kainam.app` | Manual DNS Record | DNS validation record for SSL certificate domain ownership (SUCCESS ✅) |
| **Certificate Validation Record 2** | `_d4d78920941274c3589f8456a5cc5cd4.2a57j788yh3tg66dfta7rkrte9mhdcl.senna-dev.kainam.app` | Manual DNS Record | DNS validation record for SSL certificate domain ownership (PENDING 🔄) |

**API Service Configuration:**
- **Service Name**: `kainam-senna-api-dev`
- **ECR Repository**: `592172380963.dkr.ecr.us-east-2.amazonaws.com/senna-api-ecr-dev`
- **Port**: 8080 (FastAPI application port)
- **CPU**: 1 vCPU
- **Memory**: 2 GB
- **Auto Scaling**: Enabled with min 1, max 10 instances

**Frontend Service Configuration:**
- **Service Name**: `kainam-senna-front-dev`
- **ECR Repository**: `592172380963.dkr.ecr.us-east-2.amazonaws.com/senna-front-ecr-dev`
- **Port**: 3000 (Next.js/React application port)
- **CPU**: 1 vCPU
- **Memory**: 2 GB
- **Custom Domain**: `senna-dev.kainam.app`
- **SSL Certificate**: `*.kainam.app` wildcard certificate
- **Auto Deployment**: Enabled for automatic ECR image updates

**Health Check Configuration:**
- **Protocol**: TCP (App Runner default)
- **Path**: `/` (root endpoint)
- **Timeout**: 5 seconds
- **Interval**: 10 seconds
- **Healthy Threshold**: 1 request
- **Unhealthy Threshold**: 5 requests

**VPC Integration:**
- **VPC**: kainam-dev-vpc (vpc-0c864043de1e33fe8)
- **Subnets**: kainam-dev-private-subnet-a, kainam-dev-public-subnet-b
- **VPC Connector**: Enables access to ElastiCache Redis and internal services
- **Security Group**: All outbound traffic allowed (0.0.0.0/0)

**Environment Variables:**

**API Service Status:**
- **Deployment Status**: ✅ RUNNING
- **Service URL**: `https://wdtyf4qmpn.us-east-2.awsapprunner.com`
- **Health Check**: ✅ Passing (TCP check on port 8080)
- **VPC Connectivity**: ✅ Connected to Redis and internal resources
- **SSL/TLS**: ✅ Managed by App Runner with automatic certificate

**Frontend Service Status:**
- **Deployment Status**: ✅ RUNNING
- **Service URL (Direct)**: `https://ceamr2gi9c.us-east-2.awsapprunner.com`
- **Custom Domain URL**: `https://senna-dev.kainam.app`
- **Health Check**: ✅ Passing (HTTP check on port 3000)
- **Custom Domain Status**: 🔄 Pending certificate validation completion
- **Certificate Validation**: 🔄 In Progress (1 of 2 records validated - ISSUE-014 resolution)
- **DNS Resolution**: ✅ CNAME record pointing to App Runner DNS target
- **SSL Status**: ⏳ Awaiting full certificate validation (manual DNS records created)

**Integration Features:**
- **ECR Integration**: Automatic image pulls from SENNA API ECR repository
- **IAM Roles**: Separate access and instance roles for secure operations
- **Auto Deployment**: Enabled for automatic updates on new ECR images
- **Logging**: CloudWatch logs integration for application monitoring
- **Secrets Access**: Environment variables for database and service credentials

**Connection Details:**
- **Service ARN**: `arn:aws:apprunner:us-east-2:592172380963:service/kainam-senna-api-dev/980bb0a4964a442f896a9f791bf7796f`
- **VPC Connector ARN**: `arn:aws:apprunner:us-east-2:592172380963:vpcconnector/senna-ar-vpc-connector-dev/1/7c5d2c5d8b2c4e6f8a9b0c1d2e3f4a5b`
- **Security Group ID**: `sg-0123456789abcdef0`

---

## 🖥️ EC2 Instance Module Resources

### SENNA ML Models and Celery Workers
|| Service | Resource Name | Resource Type | Description |
||---------|---------------|---------------|-------------|
|| **EC2 Instance** | `kainam-senna-celery-models-dev` | `aws_instance` | Compute instance for SENNA ML models and Celery workers |
|| **SSH Key Pair** | `kainam-senna-celery-models-key-dev` | `aws_key_pair` | SSH key pair for secure instance access |
|| **Security Group** | `kainam-senna-net-sg-ec2-dev` | `aws_security_group` | Network security controls for EC2 instance |
|| **IAM Role** | `kainam-senna-ec2-worker-role-dev` | `aws_iam_role` | IAM role with ECR and SQS permissions for workers |
|| **Instance Profile** | `kainam-senna-ec2-worker-role-dev-profile` | `aws_iam_instance_profile` | IAM role attachment for EC2 instance |
|| **Custom IAM Policy** | `senna-ec2-worker-sqs-policy` | `aws_iam_policy` | Custom policy for SQS queue access |
|| **Root EBS Volume** | N/A | `aws_ebs_block_device` | 50GB GP3 encrypted root volume |
|| **Additional EBS Volume** | N/A | `aws_ebs_volume` | 100GB GP3 encrypted additional storage |
|| **Volume Attachment** | N/A | `aws_volume_attachment` | Attach additional volume to EC2 instance |
|| **Ingress Rule** | `ssh-access` | `aws_vpc_security_group_ingress_rule` | SSH access (port 22) from anywhere |
|| **Egress Rule** | `all-outbound` | `aws_vpc_security_group_egress_rule` | All outbound traffic allowed |
|| **Policy Attachments** | ECR ReadOnly | `aws_iam_role_policy_attachment` | AWS managed policy for ECR access |

**Instance Configuration:**
- **Instance Type**: c6i.xlarge (4 vCPU, 8 GB memory)
- **AMI**: ami-0409ce19b2f39cbe2 (Amazon Linux 2023)
- **Availability Zone**: us-east-2a
- **Instance ID**: i-0fcb5b46735bed579
- **Public IP**: 18.220.146.47
- **Private IP**: 10.0.1.86

**Storage Configuration:**
- **Root Volume**: 50GB GP3 encrypted (delete on termination)
- **Additional Volume**: 100GB GP3 encrypted (persistent, mounted at /dev/sdf)
- **Total Storage**: 150GB for ML models, data processing, and system files
- **Encryption**: AWS managed encryption for both volumes

**Network Configuration:**
- **VPC**: kainam-dev-vpc (vpc-0c864043de1e33fe8)
- **Subnet**: kainam-dev-public-subnet-a (subnet-05b29d2468a820005)
- **Security Group**: kainam-senna-net-sg-ec2-dev (sg-0d44d4bf6d2acaae9)
- **SSH Access**: Port 22 from 0.0.0.0/0 (development environment)
- **Outbound Access**: All traffic to 0.0.0.0/0

**IAM Permissions:**
- **ECR Access**: Read-only permissions to all SENNA ECR repositories
- **SQS Access**: Full permissions to senna-celery-tasks-dev and senna-celery-tasks-dlq-dev queues
- **SQS Management**: CreateQueue, ListQueues, TagQueue permissions for dynamic queue management
- **Instance Profile**: Attached for seamless AWS service access

**SSH Access:**
```bash
# Connect to EC2 instance
ssh -i ~/.ssh/kainam-senna-celery-models-key-dev.pem ec2-user@18.220.146.47

# Or using SSH config alias
ssh senna-models-dev
```

**Operational Status:**
- **Instance State**: ✅ running
- **SSH Access**: ✅ Successfully tested and verified
- **IAM Role**: ✅ Attached with proper permissions
- **Storage**: ✅ Both volumes attached and encrypted
- **Monitoring**: ✅ Detailed monitoring enabled

**Use Cases:**
- **ML Model Deployment**: Deploy and run machine learning models for SENNA application
- **Celery Workers**: Process asynchronous tasks from Redis-backed queues
- **Data Processing**: Handle large datasets with 150GB total storage
- **Container Operations**: Pull Docker images from ECR repositories for deployment

---

## 🔐 Keycloak EC2 Module Resources

### Keycloak Authentication Server
|| Service | Resource Name | Resource Type | Description |
||---------|---------------|---------------|-------------|
|| **EC2 Instance** | `kainam-keycloak-dev` | `aws_instance` | Keycloak authentication service instance |
|| **SSH Key Pair** | `kainam-keycloak-dev-ssh-key` | `aws_key_pair` | Dedicated SSH key pair for Keycloak instance access |
|| **Security Group** | `kainam-keycloak-dev-sg` | `aws_security_group` | Network security controls for Keycloak instance |
|| **IAM Role** | `kainam-keycloak-dev-role` | `aws_iam_role` | IAM role with Session Manager and application permissions |
|| **Instance Profile** | `kainam-keycloak-dev-profile` | `aws_iam_instance_profile` | IAM role attachment for Keycloak instance |
|| **IAM Policy** | `kainam-keycloak-dev-policy` | `aws_iam_policy` | Custom policy for Keycloak operations and Session Manager |
|| **Target Group Attachment** | N/A | `aws_lb_target_group_attachment` | Attach Keycloak instance to ALB target group |

**Instance Configuration:**
- **Instance Type**: t3.micro (1 vCPU, 1 GB memory)
- **AMI**: ami-0c02fb55956c7d316 (Ubuntu 24.04 LTS)
- **Availability Zone**: us-east-2a
- **Instance ID**: i-0b53d307ca0b3c67e
- **Private IP**: 10.0.101.124
- **Subnet**: Private subnet (no direct internet access)

**Network Configuration:**
- **VPC**: kainam-dev-vpc (vpc-0c864043de1e33fe8)
- **Subnet**: kainam-dev-private-subnet-a (subnet-075d92a295819c6d1)
- **Security Group**: kainam-keycloak-dev-sg (sg-0cedc4b7e413fb2ed)
- **SSH Access**: Conditional SSH access from trusted IPs via Session Manager
- **ALB Integration**: HTTP traffic from ALB on port 8080

**Storage Configuration:**
- **Root Volume**: 8GB GP3 encrypted (delete on termination)
- **Encryption**: AWS managed encryption
- **Boot Optimization**: General purpose SSD for cost efficiency

**IAM Permissions:**
- **Session Manager**: Full Session Manager access for secure remote connectivity
- **CloudWatch Logs**: Write permissions for application logging
- **EC2 Metadata**: Describe instances and tags for self-management
- **Secrets Manager**: Read access to database and admin credentials

**SSH Access Configuration:**
- **SSH Key**: `kainam-keycloak-dev-ssh-key` (dedicated key pair)
- **Access Method**: AWS Session Manager with VPC endpoints
- **Trusted IPs**: Configurable IP ranges for SSH access (currently: 189.237.189.127/32)
- **Connection**: Via ProxyCommand through Session Manager plugin

**ALB Integration:**
- **Target Group**: kainam-keycloak-dev-tg
- **Health Check**: `/health/ready` endpoint on port 8080
- **Protocol**: HTTP (TLS termination at ALB)
- **Registration**: Automatic instance registration to target group

**Session Manager Access:**
```bash
# Direct Session Manager connection
aws ssm start-session --target i-0b53d307ca0b3c67e

# SSH connection through Session Manager
ssh keycloak-dev

# IDE Remote connection (VS Code/Cursor)
# Ctrl+Shift+P → "Remote-SSH: Connect to Host" → keycloak-dev
```

**VPC Endpoints for Session Manager:**
- **SSM Endpoint**: vpce-0c1c0d3843705144c (com.amazonaws.us-east-2.ssm)
- **EC2 Messages**: vpce-04344f93df79aa438 (com.amazonaws.us-east-2.ec2messages)
- **SSM Messages**: vpce-05621443a7a572c40 (com.amazonaws.us-east-2.ssmmessages)

**Operational Status:**
- **Instance State**: ✅ running
- **SSH Access**: ✅ Successfully configured with Session Manager
- **IAM Role**: ✅ Attached with proper Session Manager permissions
- **ALB Registration**: ✅ Registered to target group
- **VPC Endpoints**: ✅ Deployed and functional for private subnet access

**Use Cases:**
- **Authentication Service**: Keycloak identity and access management
- **OIDC Provider**: OAuth 2.0 and OpenID Connect authentication flows
- **User Management**: Centralized user and role administration
- **Session Management**: Secure session handling for SENNA applications

---

## 📋 Resource Summary

### Total Resource Count by Service
| AWS Service | Resource Count | Resource Types |
|-------------|----------------|----------------|
| **EC2 (VPC)** | 13 | VPC, Subnets, IGW, NAT GW, Route Tables, Associations |
| **EC2 (Security Groups)** | 10 | Security Groups, Ingress/Egress Rules (includes ALB-to-Keycloak rule) |
| **EC2 (ETL Networking)** | 15 | ETL Subnets, Security Groups, Rules, Associations |
| **ELB (Target Groups)** | 2 | Target Group, Target Group Attachments |
| **ELB (Application Load Balancer)** | 3 | ALB, HTTP Listener, HTTPS Listener |
| **Route 53 (DNS Records)** | 5 | Hosted Zone Lookup, A Records (Auth ALB), CNAME Records (SENNA + Kainam Platform) |
| **ECR (Container Registry)** | 14 | ECR Repositories (SENNA + Kainam Platform), Lifecycle Policies |
| **ElastiCache (Redis Cluster)** | 4 | Redis Replication Group, Parameter Group, Subnet Group, Security Group |
| **App Runner (Managed Containers)** | 10 | App Runner Services (SENNA + Kainam Platform), VPC Connector, Security Group, Egress Rules, Custom Domain Associations, Certificate Validation |
| **IAM (Identity & Access Management)** | 13 | OIDC Provider, Roles, Instance Profiles, Policies, Policy Attachments |
| **EC2 (Elastic IP)** | 1 | Elastic IP for NAT Gateway |
| **EC2 (Instances & Workers)** | 12 | EC2 Instance, Key Pair, Security Group, IAM Role, Volumes, Attachments |
| **CodePipeline (CI/CD Automation)** | 27 | CodePipeline workflows, CodeBuild projects, S3 artifacts bucket, IAM roles |
| **Total** | **106** | **Multiple AWS service types** |

### Resource Distribution by Module
| Module | Resources | Purpose |
|--------|-----------|---------|
| **VPC** | 13 resources | Core networking infrastructure |
| **Security Groups** | 10 resources | Network security controls (includes ALB-to-Keycloak egress rule) |
| **Kimball ETL** | 15 resources | ETL pipeline networking |
| **Authentication ALB** | 1 resource | Internet-facing load balancer for authentication service |
| **Target Groups** | 1 resource | Target group management for Keycloak instances |
| **ECR** | 14 resources | Multi-service container registry (8 SENNA + 6 Kainam Platform repositories) |
| **ElastiCache** | 4 resources | Redis replication group with SSL/TLS encryption for SENNA caching and session storage |
| **App Runner** | 8 resources | Managed container services for SENNA API and Frontend with VPC integration, custom domain, and certificate validation |
| **IAM Roles** | 13 resources | Identity and access management for SENNA services (GitHub Actions, App Runner, EC2) |
| **EC2 Workers** | 12 resources | SENNA ML models and Celery workers with encrypted storage and IAM permissions |
| **Keycloak EC2** | 7 resources | Keycloak authentication service with Session Manager access and ALB integration |
| **RDS Database** | 3 resources | PostgreSQL database for Keycloak with encrypted storage |
| **VPC Endpoints** | 3 resources | Session Manager endpoints for secure private subnet access |
| **Secrets Manager** | 3 resources | Database, Keycloak admin, and backend client secrets |
| **CodePipeline** | 27 resources | CI/CD automation for SENNA, Keycloak, and Kainam Platform applications |

### Environment-Specific Configuration
| Configuration | DEV Environment Value |
|---------------|----------------------|
| **AWS Region** | `us-east-2` |
| **VPC CIDR** | `10.0.0.0/16` |
| **Availability Zones** | `us-east-2a`, `us-east-2b` |
| **Trusted IP Ranges** | `[]` (Empty - no SSH access) |
| **ETL External Access** | `true` (Allow all external access) |
| **State Backend** | `kainam-dev-tf-state` S3 bucket |
| **State Key** | `network/dev/terraform.tfstate` |

---

## 🏷️ Resource Tagging Strategy

All resources are tagged with the following standard tags:
```
Project     = "kainam"
Environment = "dev"
Owner       = "DevOps"
ManagedBy   = "Terraform"
Purpose     = "Development"
```

Additional module-specific tags:
- **VPC Module:** `Module = "vpc"`
- **Security Groups:** `Module = "security-groups"`, `Tier = "Load Balancer|Web/Application|Database"`
- **ETL Networking:** `Module = "kimball-etl-networking"`, `Tier = "External|Internal|Database"`
- **Authentication ALB:** `Module = "auth-alb"`, `Service = "authentication"`, `Component = "load-balancer"`
- **Target Groups:** `Module = "target-groups"`, `Service = "authentication"`, `Component = "target-group"`, `Application = "keycloak"`

---

## 🔍 Resource Identification

### Name Patterns
| Resource Type | Naming Convention | Example |
|---------------|-------------------|---------|
| **VPC Resources** | `kainam-dev-{resource}` | `kainam-dev-vpc` |
| **Subnets** | `kainam-dev-{type}-subnet-{az}` | `kainam-dev-public-subnet-a` |
| **Security Groups** | `kainam-dev-{tier}-sg` | `kainam-dev-alb-sg` |
| **ETL Resources** | `kainam-dev-kimball-etl-{resource}` | `kainam-dev-kimball-etl-external-sg` |
| **Authentication ALB** | `kainam-auth-{environment}-alb` | `kainam-auth-dev-alb` |
| **Target Groups** | `kainam-{service}-{environment}-tg` | `kainam-keycloak-dev-tg` |

### ARN Patterns
| Service | ARN Format |
|---------|------------|
| **VPC** | `arn:aws:ec2:us-east-2:ACCOUNT:vpc/vpc-*` |
| **Subnet** | `arn:aws:ec2:us-east-2:ACCOUNT:subnet/subnet-*` |
| **Security Group** | `arn:aws:ec2:us-east-2:ACCOUNT:security-group/sg-*` |
| **Internet Gateway** | `arn:aws:ec2:us-east-2:ACCOUNT:internet-gateway/igw-*` |
| **NAT Gateway** | `arn:aws:ec2:us-east-2:ACCOUNT:natgateway/nat-*` |
| **Elastic IP** | `arn:aws:ec2:us-east-2:ACCOUNT:elastic-ip/eipalloc-*` |
| **CodePipeline** | `arn:aws:codepipeline:us-east-2:ACCOUNT:pipeline-name` |
| **CodeBuild Project** | `arn:aws:codebuild:us-east-2:ACCOUNT:project/project-name` |
| **S3 Bucket** | `arn:aws:s3:::bucket-name` |

## **CodePipeline Module**

**Purpose:** Automated CI/CD pipelines for SENNA and Keycloak application builds and ECR deployments.

**Location:** `/terraform/modules/codepipeline/`

### **Key Resources:**
- **CodePipelines:** 4 application-specific pipelines (Frontend, API, Models, Keycloak)
- **CodeBuild Projects:** Docker image build and ECR push automation
- **S3 Artifacts Bucket:** Pipeline artifact storage with encryption
- **IAM Roles:** Shared service roles for CodePipeline and CodeBuild execution (service-agnostic)

### **Pipeline Configuration:**
- **Trigger:** Automated builds on `dev` branch pushes
- **Source:** GitHub repositories via CodeStar Connections
- **Build:** Docker image creation with environment-specific configurations
- **Deploy:** ECR image push with proper tagging

### **Repository Mappings:**
- **Frontend:** `kainamAI/ezml-frontend` → `senna-front-ecr-dev`
- **API:** `kainamAI/ezml-fastapi` → `senna-api-ecr-dev`
- **Models:** `kainamAI/senna` → `senna-models-ecr-dev` (monorepo structure)
- **Keycloak:** `kainamAI/kainam-backend` → `keycloak-ecr-dev` (monorepo with path filtering)

### **Keycloak Pipeline Features:**
- **Monorepo Path Filtering:** Only builds when `authentication/**` files change
- **Pipeline Name:** `keycloak-cb-pipeline-dev`
- **CodeBuild Project:** `kainam-keycloak-dev-build`
- **Docker Context:** `./authentication` directory
- **Branch Trigger:** `dev` branch
- **Efficiency:** Prevents unnecessary builds on non-authentication changes

### **Buildspec Features:**
- **Inline Buildspecs:** No repository `buildspec.yml` dependency
- **ECR Integration:** Automated login, build, tag, and push
- **Environment Variables:** Application-specific build configurations
- **Monorepo Support:** Custom Dockerfile paths and path filtering for complex repository structures
- **Path Filtering:** Keycloak pipeline includes intelligent path filtering for monorepo efficiency

### **IAM Role Architecture:**
- **Shared Roles:** `kainam-dev-codepipeline-role` and `kainam-dev-codebuild-role` (service-agnostic)
- **Cost Efficiency:** Single set of IAM roles shared across SENNA and Keycloak pipelines
- **Maintainability:** Simplified IAM management with generic naming pattern

### Keycloak Realm Configuration (2025-09-10)
**KEY-28-KEYCLOAK-CONFIG Complete:**
- ✅ **Realm Creation**: kainam-dev realm configured with OIDC clients
- ✅ **SENNA Frontend Client**: Public SPA client (senna-frontend) with redirect URIs
- ✅ **SENNA Backend Client**: Confidential service client (senna-backend) with generated secret
- ✅ **Client Secret Management**: Backend client secret securely stored in AWS Secrets Manager
- ✅ **Terraform Integration**: New secret `keystone/dev/backend_client_secret` deployed via infrastructure
- ✅ **Automation Tools**: Keycloak Admin CLI script with environment support and Java prerequisite checking
- ✅ **Template System**: Dynamic realm export template with environment-specific placeholder replacement

**Infrastructure Impact:**
- **New Resources**: 3 AWS Secrets Manager resources (secrets + versions + IAM policy update)
- **Security Enhancement**: Backend client secret accessible via IAM role for SENNA applications
- **Integration Ready**: SENNA applications can now authenticate with Keycloak using stored credentials
- **Environment Isolation**: Dev-specific realm and client configuration with dynamic template system

---

## 🚨 Recent Infrastructure Updates

### Security Group Enhancements (2025-09-09)
**ISSUE-012 & ISSUE-013 Resolution:**
- ✅ **Added ALB-to-Keycloak Security Group Rule**: Direct egress rule enabling ALB health checks and traffic routing to Keycloak
- ✅ **Service Isolation**: Keycloak now operates in dedicated security group following least privilege principles  
- ✅ **Keycloak Service Operational**: Admin console accessible at `https://auth-dev.kainam.app/admin`
- ✅ **Container Health Fixed**: Docker health checks updated to use `wget` instead of `curl`
- ✅ **Total Resources**: Increased from 90 to 96 resources with additional security group rule and Secrets Manager integration

### SSL Certificate Validation Resolution (2025-09-10)
**ISSUE-014 Complete Resolution:**
- ✅ **Domain Re-association**: Successfully unlinked and re-associated `senna-dev.kainam.app` with fresh 72-hour validation window
- ✅ **Manual DNS Validation**: Added both required certificate validation records to Route 53 manually after Terraform automation timeout
- ✅ **Certificate Validation**: 1 of 2 validation records completed (SUCCESS), 1 pending validation completion
- ✅ **Terraform State Cleanup**: Removed automated validation records from Terraform state to prevent conflicts
- ✅ **Configuration Update**: Disabled automatic validation record creation (`create_senna_certificate_validation_records = false`)
- ✅ **Issue Documentation**: Complete resolution process documented in ISSUE-014 log

**Manual DNS Records Created:**
```
Record 1: _30b37806550f8f3f06e240713116efc1.senna-dev.kainam.app
→ _0cac644f22029e0bb51bebece57f30a1.xlfgrmvvlj.acm-validations.aws
Status: SUCCESS ✅

Record 2: _d4d78920941274c3589f8456a5cc5cd4.2a57j788yh3tg66dfta7rkrte9mhdcl.senna-dev.kainam.app
→ _999033f19bff17dafc43d4a51bf1e2dd.xlfgrmvvlj.acm-validations.aws
Status: PENDING_VALIDATION 🔄
```

**Resolution Process:**
- **Root Cause**: Original Terraform automation failed due to missed 72-hour validation window
- **Solution**: Manual domain re-association with fresh validation window + manual DNS record creation
- **State Management**: Terraform state cleaned up to match manual infrastructure changes
- **Monitoring**: Certificate validation in progress, expected completion within 24-48 hours

**Impact:**
- **Process Improvement**: Established manual override process for certificate validation failures
- **Documentation**: Enhanced troubleshooting procedures for App Runner SSL certificate issues
- **State Consistency**: Terraform state now properly reflects manually managed DNS validation records
- **Reliability**: Proven fallback method for certificate validation when automation fails

---

*This resource mapping reflects the current DEV environment infrastructure deployed via Terraform. All resources can be identified by the consistent naming convention and comprehensive tagging strategy.*
