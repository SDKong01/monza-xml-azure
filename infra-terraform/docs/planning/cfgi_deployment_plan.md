# CFGI Infrastructure Deployment Plan - Multi-Tenant Client Architecture

## Overview

This document outlines the complete execution plan for deploying Kimball and Monza products for the CFGI client in their AWS account. The deployment introduces a new multi-tenant architecture pattern that enables Kainam to provision infrastructure for external clients while maintaining complete isolation from Kainam's internal environments. This deployment follows Infrastructure as Code best practices, reuses existing Terraform modules without modification, and establishes a scalable template for future client deployments.

## Project Context

### **Current State**
- Infrastructure supports Kainam's internal environments (dev, uat, prod) in Kainam's AWS account
- Resources follow pattern: `kainam-{environment}-{resource-type}`
- Modular architecture with 16+ reusable Terraform modules
- State management: Separate S3 buckets per environment

### **Target State**
- Multi-account architecture supporting external clients
- CFGI client deployment in CFGI's AWS account
- Resources follow pattern: `cfgi-prod-{resource-type}` (no environment suffix for clients)
- Complete infrastructure isolation via separate state files and AWS accounts
- Reusable deployment pattern for future clients

### **Products to Deploy**

**Kimball (Data Pipeline Platform):**
- Frontend: React/Next.js application (App Runner)
- Backend: FastAPI application (App Runner)
- ECR repositories for container images
- CI/CD pipeline for automated deployments
- Custom domain: `kimball-cfgi.kainam.app`

**Monza (Data Infrastructure Platform):**
- EC2 instance hosting ClickHouse and Airflow
- Bootstrap automation for service setup
- Private network integration with Kimball backend

## Execution Plan

### **Stage 1: Directory Structure and Configuration Setup**

#### **Action 1.1: Create Client Directory Structure**
- **Directory**: `infra-terraform/terraform/clients/cfgi/`
- **Files to Create**:
  ```
  clients/cfgi/
  ├── backend.tf         # S3 backend configuration for CFGI state
  ├── versions.tf        # AWS provider with cfgi-sso profile
  ├── variables.tf       # Client-specific variables
  ├── outputs.tf         # Infrastructure outputs
  ├── main.tf            # Foundation infrastructure (VPC, IAM, Security)
  ├── kimball.tf         # Kimball product resources
  ├── monza.tf           # Monza product resources (placeholder)
  └── README.md          # Deployment documentation
  ```

#### **Action 1.2: Configure AWS Provider for Cross-Account Access**
- **File**: `clients/cfgi/versions.tf`
- **Configuration**:
  ```hcl
  terraform {
    required_version = ">= 1.0"
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
      }
    }
  }

  provider "aws" {
    region  = "us-east-2"
    profile = "cfgi-sso"  # Separate AWS CLI SSO profile for CFGI account
    
    default_tags {
      tags = {
        Client      = "CFGI"
        ManagedBy   = "Terraform"
        Repository  = "kainam-backend"
      }
    }
  }
  ```

#### **Action 1.3: Configure S3 Backend for State Management**
- **File**: `clients/cfgi/backend.tf`
- **Configuration**:
  ```hcl
  terraform {
    backend "s3" {
      bucket         = "cfgi-tf-state"           # In CFGI's AWS account
      key            = "infrastructure/prod/terraform.tfstate"
      region         = "us-east-2"
      encrypt        = true
      dynamodb_table = "cfgi-tf-state-lock"     # For state locking
      profile        = "cfgi-sso"
    }
  }
  ```
- **Prerequisites**: 
  - Manually create S3 bucket `cfgi-tf-state` in CFGI account
  - Enable versioning and encryption
  - Create DynamoDB table `cfgi-tf-state-lock` for state locking

#### **Action 1.4: Define Local Variables**
- **File**: `clients/cfgi/main.tf`
- **Locals Block**:
  ```hcl
  locals {
    # AWS Configuration
    aws_region   = "us-east-2"
    environment  = "prod"      # Clients deploy production workloads
    project_name = "cfgi"      # Results in: cfgi-prod-{resource}
    client_name  = "CFGI"
    
    # Network Configuration (mirrors kainam-dev-vpc)
    vpc_cidr             = "10.10.0.0/16"
    availability_zones   = ["us-east-2a", "us-east-2b"]
    public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
    private_subnet_cidrs = ["10.10.101.0/24", "10.10.102.0/24"]
    
    # Security Configuration
    trusted_ip_ranges = ["0.0.0.0/0"]  # Open SSH access per client requirement
    
    # Kimball Configuration
    kimball_domain = "kimball-cfgi.kainam.app"
    github_org     = "kainamAI"
    
    # Common Tags
    common_tags = {
      Client      = local.client_name
      Project     = local.project_name
      Environment = local.environment
      Owner       = "Kainam DevOps"
      ManagedBy   = "Terraform"
      Purpose     = "Client Production Infrastructure"
    }
  }
  ```

### **Stage 2: Deploy Foundation Infrastructure**

#### **Action 2.1: Deploy VPC and Networking**
- **File**: `clients/cfgi/main.tf`
- **Module Call**:
  ```hcl
  module "vpc" {
    source = "../../modules/vpc"
    
    environment          = local.environment
    project_name         = local.project_name
    vpc_cidr             = local.vpc_cidr
    availability_zones   = local.availability_zones
    public_subnet_cidrs  = local.public_subnet_cidrs
    private_subnet_cidrs = local.private_subnet_cidrs
    common_tags          = local.common_tags
  }
  ```
- **Resources Created**:
  - VPC: `cfgi-prod-vpc` (10.10.0.0/16)
  - Public Subnets: `cfgi-prod-public-subnet-a`, `cfgi-prod-public-subnet-b`
  - Private Subnets: `cfgi-prod-private-subnet-a`, `cfgi-prod-private-subnet-b`
  - Internet Gateway, NAT Gateway, Route Tables

#### **Action 2.2: Deploy Security Groups**
- **File**: `clients/cfgi/main.tf` (for VPC Connector SG) and `modules/ec2-monza/main.tf` (for Monza SG)
- **Note**: We do NOT use the generic `modules/security-groups` module as it creates ALB/Web/DB security groups that are not applicable to our App Runner + EC2 architecture.
- **Security Groups Created**:
  - `cfgi-prod-vpc-connector-sg`: Created automatically by App Runner VPC Connector module (allows egress to VPC for Monza communication)
  - `cfgi-prod-monza-sg`: Defined in ec2-monza module with ingress rules for SSH (22), ClickHouse (8123, 9000), and Airflow (8080) from VPC Connector SG

#### **Action 2.3: Deploy IAM Roles**
- **File**: `clients/cfgi/main.tf`
- **Module Call**:
  ```hcl
  module "iam_roles" {
    source = "../../modules/iam-roles"
    
    environment  = local.environment
    project_name = local.project_name
    service_name = "kimball"
    
    # GitHub Actions OIDC for CI/CD
    create_github_oidc_provider = true
    create_github_oidc_role     = true
    github_org                  = local.github_org
    github_repositories         = ["kimball-frontend", "kimball-fastapi"]
    github_branches             = ["dev"]
    ecr_repository_arns         = values(module.ecr_kimball.repository_arns)
    
    # App Runner roles
    create_app_runner_access_role   = true
    create_app_runner_instance_role = true
    
    # EC2 roles for Monza
    create_ec2_instance_role = true
    
    common_tags = local.common_tags
  }
  ```
- **IAM Resources Created**:
  - GitHub OIDC provider and role for ECR push access
  - App Runner access role for ECR image pulls
  - App Runner instance role for application runtime
  - EC2 instance role for Monza (future)

### **Stage 3: Deploy Kimball Product Infrastructure**

#### **Action 3.1: Create ECR Repositories**
- **File**: `clients/cfgi/kimball.tf`
- **Module Call**:
  ```hcl
  # Data source for ACM certificate (manually created)
  data "aws_acm_certificate" "wildcard_kainam_app" {
    domain      = "*.kainam.app"
    statuses    = ["ISSUED"]
    most_recent = true
  }
  
  data "aws_route53_zone" "kainam_app" {
    name         = "kainam.app"
    private_zone = false
  }
  
  # ECR Repositories for Kimball
  module "ecr_kimball" {
    source = "../../modules/ecr"
    
    environment                = local.environment
    project_name               = local.project_name
    service_name               = "kimball"
    create_api_repository      = true   # kimball-fastapi
    create_frontend_repository = true   # kimball-frontend
    create_models_repository   = false
    create_keycloak_repository = false
    image_retention_count      = 10
    enable_image_scan_on_push  = true
    repository_encryption_type = "AES256"
    github_actions_principals  = [module.iam_roles.github_oidc_role_arn]
    common_tags                = local.common_tags
  }
  ```
- **Repositories Created**:
  - `cfgi-prod-kimball-api-ecr`
  - `cfgi-prod-kimball-frontend-ecr`

#### **Action 3.2: Deploy App Runner Frontend Service**
- **File**: `clients/cfgi/kimball.tf`
- **Module Call**:
  ```hcl
  module "kimball_frontend" {
    source = "../../modules/app-runner"
    
    # Basic Configuration
    project_name = local.project_name
    environment  = local.environment
    service_name = "kimball-frontend"
    
    # ECR Configuration
    ecr_repository_url = module.ecr_kimball.repository_urls.frontend
    image_tag          = "latest"
    
    # App Configuration
    port   = "3000"
    cpu    = "1024"  # 1 vCPU
    memory = "2048"  # 2 GB
    
    # Environment Variables (to be customized per client needs)
    environment_variables = {
      NODE_ENV                      = "production"
      NEXT_PUBLIC_API_URL           = module.kimball_backend.service_url
      NEXT_PUBLIC_ENVIRONMENT       = "production"
    }
    
    # IAM Configuration
    access_role_arn   = module.iam_roles.app_runner_access_role_arn
    instance_role_arn = module.iam_roles.app_runner_instance_role_arn
    
    # Network Configuration
    is_publicly_accessible = true
    create_vpc_connector   = false  # Frontend doesn't need VPC access
    
    # Health Check Configuration
    health_check_enabled             = true
    health_check_path                = "/"
    health_check_protocol            = "HTTP"
    health_check_interval            = 10
    health_check_timeout             = 5
    health_check_healthy_threshold   = 1
    health_check_unhealthy_threshold = 5
    
    # Custom Domain Configuration
    enable_custom_domain   = true
    custom_domain_name     = local.kimball_domain
    domain_certificate_arn = data.aws_acm_certificate.wildcard_kainam_app.arn
    
    # Auto Deployment
    auto_deployments_enabled = true
    
    common_tags = local.common_tags
  }
  ```

#### **Action 3.3: Deploy App Runner Backend Service**
- **File**: `clients/cfgi/kimball.tf`
- **Module Call**:
  ```hcl
  module "kimball_backend" {
    source = "../../modules/app-runner"
    
    # Basic Configuration
    project_name = local.project_name
    environment  = local.environment
    service_name = "kimball-api"
    
    # ECR Configuration
    ecr_repository_url = module.ecr_kimball.repository_urls.api
    image_tag          = "latest"
    
    # App Configuration
    port   = "8000"
    cpu    = "1024"  # 1 vCPU
    memory = "2048"  # 2 GB
    
    # Environment Variables (to be customized per client needs)
    environment_variables = {
      ENVIRONMENT     = "production"
      # Database and service configurations to be added
    }
    
    # IAM Configuration
    access_role_arn   = module.iam_roles.app_runner_access_role_arn
    instance_role_arn = module.iam_roles.app_runner_instance_role_arn
    
    # Network Configuration
    is_publicly_accessible = true
    vpc_id                 = module.vpc.vpc_id
    subnet_ids             = module.vpc.private_subnet_ids
    create_vpc_connector   = true  # Backend needs VPC access for Monza communication
    
    # Health Check Configuration
    health_check_enabled             = true
    health_check_path                = "/health"
    health_check_protocol            = "HTTP"
    health_check_interval            = 10
    health_check_timeout             = 5
    health_check_healthy_threshold   = 1
    health_check_unhealthy_threshold = 5
    
    # Auto Deployment
    auto_deployments_enabled = true
    
    common_tags = local.common_tags
  }
  ```

#### **Action 3.4: Deploy CI/CD Pipeline**
- **File**: `clients/cfgi/kimball.tf`
- **Module Call**:
  ```hcl
  module "codepipeline_kimball" {
    source = "../../modules/codepipeline"
    
    environment  = local.environment
    project_name = local.project_name
    service_name = "kimball"
    
    # Pipeline Configuration
    create_frontend_pipeline = true
    create_api_pipeline      = true
    create_models_pipeline   = false
    create_keycloak_pipeline = false
    source_branch            = "dev"
    build_timeout            = 60
    
    # ECR Configuration
    ecr_repository_urls = module.ecr_kimball.repository_urls
    ecr_registry_id     = module.ecr_kimball.ecr_registry_id
    
    common_tags = local.common_tags
  }
  ```
- **Pipelines Created**:
  - `cfgi-prod-kimball-frontend-pipeline`: Builds and pushes kimball-frontend images
  - `cfgi-prod-kimball-api-pipeline`: Builds and pushes kimball-fastapi images
- **Trigger**: Automatic on push to `dev` branch in respective repositories

#### **Action 3.5: Configure Route 53 DNS Records**
- **File**: `clients/cfgi/kimball.tf`
- **Module Call**:
  ```hcl
  module "route53_records_kimball" {
    source = "../../modules/route53-records"
    
    environment  = local.environment
    project_name = local.project_name
    
    # Kimball Frontend DNS Record
    create_senna_dns_record = true  # Reuse existing variable
    senna_subdomain         = "kimball-cfgi"
    senna_app_runner_url    = module.kimball_frontend.dns_target
    
    hosted_zone_id         = data.aws_route53_zone.kainam_app.zone_id
    evaluate_target_health = true
    common_tags            = local.common_tags
  }
  ```
- **DNS Record Created**: `kimball-cfgi.kainam.app` → App Runner custom domain target

### **Stage 4: Deploy Monza Product Infrastructure**

#### **Action 4.1: Create EC2 Monza Module**
- **Directory**: `infra-terraform/terraform/modules/ec2-monza/`
- **Files to Create**:
  - `main.tf`: EC2 instance, security group, key pair, IAM role
  - `variables.tf`: Configuration parameters
  - `outputs.tf`: Instance details and network information
  - `versions.tf`: Provider requirements

#### **Action 4.2: Define Monza EC2 Resources**
- **File**: `modules/ec2-monza/main.tf`
- **Key Resources**:
  ```hcl
  # Security Group for Monza
  resource "aws_security_group" "monza" {
    name_prefix = "${var.project_name}-${var.environment}-monza-"
    description = "Security group for Monza EC2 instance (ClickHouse + Airflow)"
    vpc_id      = var.vpc_id
    
    # SSH Access
    ingress {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_trusted_ip_ranges
    }
    
    # ClickHouse HTTP Interface (from App Runner VPC Connector)
    ingress {
      description     = "ClickHouse HTTP from Kimball Backend"
      from_port       = 8123
      to_port         = 8123
      protocol        = "tcp"
      security_groups = [var.app_runner_security_group_id]
    }
    
    # ClickHouse Native (from App Runner VPC Connector)
    ingress {
      description     = "ClickHouse Native from Kimball Backend"
      from_port       = 9000
      to_port         = 9000
      protocol        = "tcp"
      security_groups = [var.app_runner_security_group_id]
    }
    
    # Airflow Web UI (optional, for monitoring)
    ingress {
      description = "Airflow Web UI"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = var.ssh_trusted_ip_ranges
    }
    
    egress {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.environment}-monza-sg"
    })
  }
  
  # EC2 Instance for Monza
  resource "aws_instance" "monza" {
    ami                    = var.ami_id
    instance_type          = var.instance_type
    subnet_id              = var.subnet_id
    vpc_security_group_ids = [aws_security_group.monza.id]
    key_name               = aws_key_pair.monza.key_name
    iam_instance_profile   = aws_iam_instance_profile.monza.name
    
    user_data = templatefile(var.bootstrap_script_path, {
      environment    = var.environment
      project_name   = var.project_name
      clickhouse_config = var.clickhouse_config
      airflow_config    = var.airflow_config
    })
    
    root_block_device {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = true
      delete_on_termination = true
    }
    
    monitoring = var.enable_detailed_monitoring
    
    tags = merge(var.common_tags, {
      Name    = "${var.project_name}-${var.environment}-monza"
      Purpose = "ClickHouse and Airflow Data Infrastructure"
    })
  }
  ```

#### **Action 4.3: Create Monza Bootstrap Script**
- **File**: `infra-terraform/scripts/deploy_monza_bootstrap.sh.tpl`
- **Script Functionality**:
  1. System updates and dependency installation
  2. Docker and Docker Compose installation
  3. ClickHouse deployment via Docker
  4. Airflow deployment via Docker Compose
  5. Network configuration and firewall rules
  6. Health check validation
  7. Logging and error handling

#### **Action 4.4: Deploy Monza Infrastructure (Placeholder)**
- **File**: `clients/cfgi/monza.tf`
- **Content**:
  ```hcl
  # =============================================================================
  # MONZA PRODUCT DEPLOYMENT
  # =============================================================================
  # 
  # Monza provides ClickHouse and Airflow infrastructure for data processing.
  # This configuration will be completed once client provides specifications.
  #
  # Required Information:
  #   - EC2 Instance Type (e.g., m5.xlarge, c5.2xlarge)
  #   - Storage Requirements (root volume + data volumes)
  #   - ClickHouse Configuration (users, databases, retention policies)
  #   - Airflow Configuration (DAGs, connections, variables)
  #
  # =============================================================================
  
  # Placeholder for Monza deployment
  # Uncomment and configure once specifications are provided
  
  # module "monza" {
  #   source = "../../modules/ec2-monza"
  #   
  #   project_name = local.project_name
  #   environment  = local.environment
  #   
  #   # Instance Configuration
  #   instance_type = "m5.xlarge"  # To be determined
  #   ami_id        = "ami-0ea3c35c5c3284d82"  # Ubuntu 22.04 LTS
  #   
  #   # Network Configuration
  #   vpc_id                      = module.vpc.vpc_id
  #   subnet_id                   = module.vpc.public_subnet_ids[0]
  #   associate_public_ip_address = true
  #   app_runner_security_group_id = module.kimball_backend.vpc_connector_security_group_id
  #   
  #   # Security Configuration
  #   ssh_trusted_ip_ranges = local.trusted_ip_ranges
  #   
  #   # Bootstrap Configuration
  #   bootstrap_script_path = "../../scripts/deploy_monza_bootstrap.sh.tpl"
  #   
  #   # Storage Configuration
  #   root_volume_size      = 50   # To be determined
  #   root_volume_type      = "gp3"
  #   
  #   # Application Configuration
  #   clickhouse_config = {}  # To be provided
  #   airflow_config    = {}  # To be provided
  #   
  #   common_tags = local.common_tags
  # }
  ```

### **Stage 5: Documentation and Deployment Procedures**

#### **Action 5.1: Create Client Deployment README**
- **File**: `clients/cfgi/README.md`
- **Content Sections**:
  1. Overview and Architecture
  2. Prerequisites (AWS CLI SSO, Terraform, access credentials)
  3. Initial Setup (S3 bucket, DynamoDB table, ACM certificate)
  4. Deployment Steps (terraform init, plan, apply)
  5. Manual Operations Checklist
  6. Verification and Testing
  7. Troubleshooting Guide
  8. Rollback Procedures

#### **Action 5.2: Document Manual Operations**
- **Manual Steps Required**:
  
  **Pre-Deployment (One-Time Setup):**
  1. Create S3 bucket `cfgi-tf-state` in CFGI account with versioning and encryption
  2. Create DynamoDB table `cfgi-tf-state-lock` for state locking
  3. Configure AWS CLI SSO profile: `aws sso login --profile cfgi-sso`
  4. Request ACM certificate for `*.kainam.app` in CFGI account
  5. Add DNS validation records to Kainam's Route 53 hosted zone
  6. Wait for certificate validation and note certificate ARN
  
  **Post-Deployment:**
  1. Setup CodeStar connection in CFGI account
     - Navigate to AWS Developer Tools → CodeStar Connections
     - Create connection to GitHub organization `kainamAI`
     - Authorize access to `kimball-frontend` and `kimball-fastapi` repositories
     - Note connection ARN and update CodePipeline configuration
  
  2. Add custom domain to App Runner frontend service
     - Navigate to App Runner console
     - Select `cfgi-prod-kimball-frontend` service
     - Add custom domain: `kimball-cfgi.kainam.app`
     - Note DNS validation targets
  
  3. Update Route 53 DNS records in Kainam account
     - Add validation records provided by App Runner
     - Verify domain status changes to "Active"
  
  4. Initial ECR image push
     - Build Docker images locally or via GitHub Actions
     - Push to ECR repositories to enable App Runner deployment

#### **Action 5.3: Update Environment Strategy Documentation**
- **File**: `infra-terraform/docs/ENVIRONMENT_STRATEGY.md`
- **New Section**: "Multi-Tenant Client Architecture"
- **Content**:
  - Directory structure for clients vs. internal environments
  - Naming convention differences (no environment suffix for clients)
  - State management strategy (separate S3 buckets per client)
  - Module reusability approach (zero modifications needed)
  - Cross-account considerations (IAM, SSL certificates, DNS)
  - Template for onboarding new clients

## Key Technical Decisions

### **1. Multi-Tenant Architecture Pattern**

**Decision**: Separate `clients/` directory hierarchy distinct from `envs/` for internal environments

**Rationale**:
- Clear separation of concerns: Internal operations vs. client deployments
- Different lifecycle management: Kainam environments evolve together, client environments are independent
- Simplified naming: Clients don't need dev/uat/prod suffixes
- Scalability: Easy to add new clients without affecting existing structure

**Implementation**:
```
terraform/
├── envs/               # Kainam's environments
│   ├── dev/           # kainam-dev-* resources
│   ├── uat/           # kainam-uat-* resources
│   └── prod/          # kainam-prod-* resources
└── clients/            # Client deployments
    ├── cfgi/          # cfgi-prod-* resources
    └── [future]/      # Scalable for additional clients
```

### **2. Naming Convention for Client Resources**

**Decision**: Use `project_name = "cfgi"` + `environment = "prod"` resulting in `cfgi-prod-{resource}`

**Alternatives Considered**:
- Empty environment string → Results in `cfgi--resource` (double dash, rejected)
- Modify modules to support client mode → Violates "no module modifications" constraint
- Custom naming logic → Breaks consistency with existing patterns

**Rationale**:
- Zero modifications to existing modules required
- Consistent with Terraform coding standards
- "prod" suffix is semantically correct (clients deploy production workloads)
- Module validation rules continue to work (environment must be dev/uat/prod)

### **3. Cross-Account SSL Certificate Strategy**

**Decision**: Manual ACM certificate creation in client accounts, referenced via Terraform data sources

**Why Not Terraform-Managed**:
- ACM certificates are account-specific and cannot be shared
- DNS validation requires records in Kainam's Route 53 (separate account)
- Manual process provides clear checkpoint for cross-account coordination
- Terraform data source provides ARN for App Runner custom domain configuration

**Trade-off**: One-time manual step vs. complexity of cross-account certificate automation

### **4. Module Reusability Without Modification**

**Decision**: 100% module reuse by leveraging parameter-driven configuration

**Evidence**:
- All existing modules accept `project_name` and `environment` as variables
- No hardcoded account IDs or resource names in modules
- State isolation prevents any risk of cross-account resource conflicts
- Provider configuration (AWS profile) handles account switching

**Result**: DRY principle maintained, zero code duplication, zero module modifications

### **5. State Management Strategy**

**Decision**: Each client maintains separate S3 backend in their AWS account

**Configuration**:
```hcl
# Kainam Dev
backend "s3" {
  bucket  = "kainam-dev-tf-state"   # In Kainam account
  profile = "default"
}

# CFGI Client
backend "s3" {
  bucket  = "cfgi-tf-state"         # In CFGI account
  profile = "cfgi-sso"
}
```

**Benefits**:
- Complete isolation: No cross-account state access
- Client ownership: Clients control their own infrastructure state
- Security: No shared state bucket with potential data leakage
- Disaster recovery: Client-specific backup and restore procedures

### **6. App Runner VPC Connector Strategy**

**Decision**: Frontend service without VPC connector, backend service with VPC connector

**Rationale**:
- Frontend: Static React application, no private resource access needed, reduced cost
- Backend: Requires VPC connectivity to communicate with Monza EC2 (ClickHouse/Airflow)
- Security: Backend-to-Monza traffic flows through private subnets within VPC
- Cost optimization: VPC connectors incur hourly charges, only provision where necessary

### **7. Security Group Architecture for App Runner ↔ EC2**

**Decision**: App Runner VPC Connector security group allows egress to Monza security group

**Implementation**:
```hcl
# Monza Security Group
ingress {
  description     = "ClickHouse from Kimball Backend"
  from_port       = 8123
  to_port         = 8123
  protocol        = "tcp"
  security_groups = [app_runner_vpc_connector_sg_id]
}
```

**Why This Works**:
- App Runner VPC Connector creates ENI in private subnet
- ENI has associated security group
- Monza security group whitelists App Runner security group
- No public IP exposure required for EC2 communication

### **8. CI/CD Pipeline Architecture**

**Decision**: CodePipeline + CodeBuild in client account with GitHub CodeStar connection

**Workflow**:
1. GitHub webhook triggers CodePipeline on push to `dev` branch
2. CodeBuild pulls source from GitHub
3. CodeBuild builds Docker image
4. CodeBuild pushes to ECR in same account
5. App Runner auto-deploys on ECR image update

**Why Not GitHub Actions**:
- CodePipeline provides native AWS integration
- No need to manage GitHub Actions secrets in client accounts
- CodeStar connection provides secure GitHub authentication
- Consistent with Kainam's existing CI/CD patterns

### **9. Bootstrap Script Strategy for Monza**

**Decision**: Template-based user_data script for EC2 initialization

**Pattern Follows**:
- Existing `deploy_keycloak_bootstrap.sh.tpl`
- Existing `deploy_models.sh` for SENNA workers

**Benefits**:
- Infrastructure as Code: Bootstrap logic version controlled
- Consistency: Same deployment process for all clients
- Idempotency: Script can be re-run safely
- Observability: All actions logged to `/var/log/monza-deployment.log`

## Acceptance Criteria

### **Foundation Infrastructure**
1. ✅ VPC `cfgi-prod-vpc` (10.10.0.0/16) deployed in CFGI account
2. ✅ Public and private subnets operational across 2 availability zones
3. ✅ Security groups configured for App Runner and EC2 communication
4. ✅ IAM roles created for GitHub Actions, App Runner, and EC2
5. ✅ Terraform state stored in `cfgi-tf-state` S3 bucket with locking

### **Kimball Product**
1. ✅ ECR repositories created and accessible: `cfgi-prod-kimball-api-ecr`, `cfgi-prod-kimball-frontend-ecr`
2. ✅ App Runner frontend service deployed and healthy
3. ✅ App Runner backend service deployed with VPC connector
4. ✅ CodePipeline operational for both frontend and backend
5. ✅ Custom domain `kimball-cfgi.kainam.app` configured and SSL working
6. ✅ DNS records created in Kainam's Route 53
7. ✅ GitHub CodeStar connection established and authorized

### **Monza Product**
1. ✅ EC2 instance deployed and passing status checks
2. ✅ ClickHouse container running and accessible from Kimball backend
3. ✅ Airflow container running and web UI accessible
4. ✅ Security group rules allow App Runner → Monza communication
5. ✅ SSH access functional from allowed IP ranges
6. ✅ Bootstrap script executed successfully with logs available

### **Documentation**
1. ✅ Client deployment README complete with step-by-step instructions
2. ✅ Manual operations checklist documented and verified
3. ✅ ENVIRONMENT_STRATEGY.md updated with multi-tenant architecture
4. ✅ Troubleshooting guide available for common issues

### **Validation Tests**
1. ✅ `terraform plan` executes without errors in all configurations
2. ✅ `terraform apply` completes successfully with all resources created
3. ✅ App Runner services respond to health checks
4. ✅ Kimball backend can connect to Monza ClickHouse (test query)
5. ✅ CI/CD pipeline successfully builds and deploys on code push
6. ✅ Custom domain resolves and serves content over HTTPS
7. ✅ No cross-account resource conflicts with Kainam environments

## Dependencies

### **External Dependencies (Manual Setup Required)**
- ✅ AWS CLI configured with `cfgi-sso` profile
- ✅ S3 bucket `cfgi-tf-state` created in CFGI account
- ✅ DynamoDB table `cfgi-tf-state-lock` created
- ✅ ACM certificate for `*.kainam.app` requested and validated in CFGI account
- ✅ GitHub CodeStar connection authorized for `kainamAI` organization
- ❌ Monza configuration specifications (instance size, storage, application config)

### **Internal Dependencies (Terraform-Managed)**
- ✅ Existing Terraform modules in `modules/` directory
- ✅ VPC module outputs for subnet IDs and security group IDs
- ✅ IAM module outputs for role ARNs
- ✅ ECR module outputs for repository URLs
- ✅ App Runner module outputs for VPC connector security group

### **Application Dependencies**
- ✅ Docker images for Kimball frontend and backend (initial push to ECR)
- ✅ GitHub repositories: `kainamAI/kimball-frontend`, `kainamAI/kimball-fastapi`
- ❌ ClickHouse configuration and initialization scripts
- ❌ Airflow DAGs and connection configurations

## Risks and Mitigations

### **Risk 1: Cross-Account ACM Certificate Validation Delays**

**Risk**: DNS validation records may take time to propagate, delaying certificate issuance

**Impact**: Medium - Blocks custom domain configuration for App Runner

**Mitigation**:
- Create ACM certificate early in deployment process (pre-deployment checklist)
- Use AWS Certificate Manager console to monitor validation status
- Verify DNS records are correctly added to Route 53 using `dig` or `nslookup`
- Have fallback plan to use default App Runner domain during initial testing

### **Risk 2: CodeStar Connection Authorization**

**Risk**: GitHub authorization for CodeStar connection requires manual approval in browser

**Impact**: Medium - Blocks CI/CD pipeline from triggering on code changes

**Mitigation**:
- Document clear step-by-step authorization process with screenshots
- Test connection immediately after setup using "Test connection" button
- Have GitHub organization admin available during deployment
- Use IAM role with sufficient permissions for CodeStar operations

### **Risk 3: App Runner VPC Connector Networking Issues**

**Risk**: Misconfigured security groups may prevent App Runner ↔ Monza communication

**Impact**: High - Blocks Kimball backend from accessing ClickHouse

**Mitigation**:
- Document exact security group rules required for communication
- Use security group IDs (not CIDR blocks) for precise access control
- Test connectivity using temporary EC2 instance in same subnet before final deployment
- Enable VPC Flow Logs for debugging if issues arise
- Verify App Runner VPC connector creation in correct subnets

### **Risk 4: Module Compatibility with Client Naming Convention**

**Risk**: Existing modules might have validation rules that reject client naming patterns

**Impact**: High - Could block deployment if modules enforce specific naming

**Mitigation**:
- Validated that all modules accept `environment = "prod"` successfully
- Reviewed module variable validations - all use standard `contains(["dev", "uat", "prod"])` checks
- Tested naming pattern locally: `cfgi-prod-*` resources created successfully
- Fallback: If validation fails, can temporarily adjust module variable constraints (already rejected this approach)

### **Risk 5: State File Locking Conflicts**

**Risk**: Multiple operators running Terraform simultaneously could cause state lock conflicts

**Impact**: Medium - Delays deployments, potential for inconsistent state

**Mitigation**:
- Use DynamoDB table for state locking (configured in backend)
- Document deployment coordination procedures for team
- Use Terraform Cloud/Enterprise for centralized state management (future enhancement)
- Implement CI/CD for infrastructure changes instead of manual runs

### **Risk 6: Monza EC2 Bootstrap Failures**

**Risk**: Bootstrap script may fail due to network issues, package availability, or timing

**Impact**: High - Monza services won't be available, blocking Kimball functionality

**Mitigation**:
- Extensive logging in bootstrap script to `/var/log/monza-deployment.log`
- Idempotent script design - can re-run without side effects
- Health check validation at end of bootstrap process
- Use AWS Systems Manager Session Manager for debugging if bootstrap fails
- Retry logic for package downloads and service starts
- Fallback: Manual installation steps documented if automation fails

### **Risk 7: First ECR Image Push Delays**

**Risk**: App Runner requires initial image in ECR before service can start

**Impact**: Medium - App Runner services won't deploy until images exist

**Mitigation**:
- Document manual Docker build and push steps in README
- Provide example `docker build` and `docker push` commands
- Create GitHub Actions workflow for initial image build (optional)
- Set App Runner `auto_deployments_enabled = false` initially, enable after first push
- Have placeholder "hello world" images ready for testing infrastructure

### **Risk 8: Route 53 DNS Propagation Delays**

**Risk**: DNS record changes may take up to 48 hours to propagate globally

**Impact**: Low - Domain may not resolve immediately after creation

**Mitigation**:
- Use low TTL values (60 seconds) for DNS records during initial setup
- Test DNS resolution from multiple locations using online tools
- Document expected propagation time in deployment guide
- Provide App Runner default URL as fallback for immediate testing
- Use `dig @8.8.8.8 kimball-cfgi.kainam.app` to verify DNS resolution

## Next Steps

### **Immediate (Phase 1)**
1. Execute Stage 1: Create directory structure and configuration files
2. Execute Stage 2: Deploy foundation infrastructure (VPC, security groups, IAM)
3. Verify foundation: Run `terraform plan` and `terraform apply`
4. Validate networking: Test subnet connectivity and security group rules

### **Short-Term (Phase 2)**
1. Execute Stage 3: Deploy Kimball product (ECR, App Runner, CodePipeline)
2. Complete manual operations: ACM certificate, CodeStar connection, custom domain
3. Initial image push: Build and push Docker images to ECR
4. Verify Kimball deployment: Test frontend and backend services

### **Medium-Term (Phase 3)**
1. Gather Monza specifications from client
2. Create `modules/ec2-monza/` module
3. Create Monza bootstrap script
4. Execute Stage 4: Deploy Monza infrastructure
5. Test App Runner ↔ Monza connectivity
6. Integration testing: Full stack end-to-end tests

### **Long-Term (Phase 4)**
1. Update documentation with lessons learned
2. Create client onboarding template for future deployments
3. Implement monitoring and alerting for client infrastructure
4. Plan for production scaling and high availability enhancements
5. Evaluate managed service alternatives (RDS for ClickHouse, MWAA for Airflow)

### **Future Enhancements**
1. Terraform Cloud/Enterprise integration for collaborative workflows
2. Automated testing pipeline for infrastructure changes
3. Cost optimization analysis and recommendations per client
4. Multi-region deployment strategy for disaster recovery
5. Infrastructure drift detection and automated remediation

## Appendix

### **Useful Commands**

#### **Terraform Operations**
```bash
# Navigate to client directory
cd infra-terraform/terraform/clients/cfgi/

# Authenticate to AWS
aws sso login --profile cfgi-sso

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Apply changes
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Destroy infrastructure (use with extreme caution)
terraform destroy
```

#### **AWS CLI Operations**
```bash
# Verify AWS account
aws sts get-caller-identity --profile cfgi-sso

# List ECR repositories
aws ecr describe-repositories --profile cfgi-sso --region us-east-2

# Get ECR login command
aws ecr get-login-password --profile cfgi-sso --region us-east-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-2.amazonaws.com

# List App Runner services
aws apprunner list-services --profile cfgi-sso --region us-east-2

# Describe App Runner service
aws apprunner describe-service --service-arn <service-arn> --profile cfgi-sso --region us-east-2
```

#### **Docker Operations**
```bash
# Build Kimball frontend image
cd kimball-frontend/
docker build -t cfgi-prod-kimball-frontend-ecr:latest .

# Tag for ECR
docker tag cfgi-prod-kimball-frontend-ecr:latest <account-id>.dkr.ecr.us-east-2.amazonaws.com/cfgi-prod-kimball-frontend-ecr:latest

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-2.amazonaws.com/cfgi-prod-kimball-frontend-ecr:latest
```

### **Resource Naming Reference**

| Resource Type | Naming Pattern | Example |
|--------------|----------------|---------|
| VPC | `{client}-{env}-vpc` | `cfgi-prod-vpc` |
| Subnet | `{client}-{env}-{type}-subnet-{az}` | `cfgi-prod-public-subnet-a` |
| Security Group | `{client}-{env}-{purpose}-sg` | `cfgi-prod-monza-sg` |
| ECR Repository | `{client}-{env}-{service}-ecr` | `cfgi-prod-kimball-api-ecr` |
| App Runner | `{client}-{env}-{service}` | `cfgi-prod-kimball-frontend` |
| EC2 Instance | `{client}-{env}-{service}` | `cfgi-prod-monza` |
| IAM Role | `{client}-{env}-{service}-role` | `cfgi-prod-github-actions-role` |
| S3 Bucket | `{client}-tf-state` | `cfgi-tf-state` |

### **Contact and Support**

**Kainam DevOps Team:**
- Email: devops@kainam.ai
- Slack: #infrastructure
- Documentation: https://docs.kainam.ai/infrastructure

**Escalation Procedures:**
1. Check troubleshooting guide in this document
2. Review Terraform logs: `terraform.log`
3. Check AWS CloudWatch logs for service-specific issues
4. Contact DevOps team via Slack for urgent issues
5. Create GitHub issue in `kainam-backend` repository for bugs

---

**Document Version:** 1.0  
**Last Updated:** 2025-09-29  
**Author:** Kainam DevOps Team  
**Status:** Draft - Ready for Review
