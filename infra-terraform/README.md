# Kainam Infrastructure - Terraform

## Project Overview

Kainam Infrastructure is a production-ready, enterprise-grade Infrastructure as Code (IaC) solution built with Terraform for the Kainam Platform. It provides a comprehensive, scalable, and secure AWS cloud infrastructure foundation that supports authentication services, ETL pipelines, and multi-environment deployments with consistent resource provisioning and management.

The system solves the complex challenge of managing cloud infrastructure across multiple environments (development, UAT, production) while maintaining infrastructure consistency, security best practices, and cost optimization. Unlike traditional infrastructure approaches that require manual configuration and are prone to drift, Kainam Infrastructure provides a modular, repeatable deployment architecture that ensures identical configurations across environments with environment-specific customizations where needed.

## Table of Contents

- [Project Overview](#project-overview)
- [Get Started](#get-started)
  - [Prerequisites](#prerequisites)
- [Usage](#usage)
  - [Infrastructure Deployment](#infrastructure-deployment)
  - [Environment Management](#environment-management)
  - [Secrets Management](#secrets-management)
- [Tech We Use](#tech-we-use)
- [Features](#features)
- [Architecture](#architecture)
- [Current Infrastructure Status](#current-infrastructure-status)
- [Developer Notes](#developer-notes)

## Get Started

### Prerequisites

- **Terraform** (version 1.0+) with AWS provider support
- **AWS CLI v2** configured with appropriate credentials and permissions
- **Git** for cloning the repository
- For production deployments:
  - AWS account with VPC quota sufficient for your infrastructure needs
  - IAM permissions for creating VPCs, subnets, security groups, secrets, and IAM roles
  - S3 buckets for Terraform state storage (with versioning and encryption enabled)

## Usage

### Infrastructure Deployment

**Deploy to different environments:**

```bash
# Development environment
cd infra-terraform/terraform/envs/dev/
terraform plan && terraform apply

# UAT environment  
cd infra-terraform/terraform/envs/uat/
terraform plan && terraform apply

# Production environment
cd infra-terraform/terraform/envs/prod/
terraform plan -var-file="../../secrets.tfvars" && terraform apply -var-file="../../secrets.tfvars"
```

### Environment Management

**Managing multiple environments:**

Each environment maintains isolated state and configuration:

```bash
# Check current environment state
terraform show

# Import existing resources (if needed)
terraform import aws_vpc.main vpc-1234567890abcdef0

# Destroy environment (use with caution)
terraform destroy
```

### Secrets Management

**Working with AWS Secrets Manager:**

```bash
# Generate new passwords
bash scripts/generate_keystone_passwords.sh

# Validate secrets configuration
terraform plan -var-file="secrets.tfvars"

# Update secrets in AWS
terraform apply -var-file="secrets.tfvars"

# Test secrets access (from EC2 with proper IAM role)
aws secretsmanager get-secret-value --secret-id "keystone/dev/database" --query SecretString --output text
```

**For applications integrating with the infrastructure:**

Your EC2 instances will have access to secrets through the IAM role:

```bash
# Example: Fetch database credentials
DATABASE_SECRET=$(aws secretsmanager get-secret-value --secret-id "keystone/dev/database" --query SecretString --output text)
DB_USERNAME=$(echo $DATABASE_SECRET | jq -r '.username')
DB_PASSWORD=$(echo $DATABASE_SECRET | jq -r '.password')

# Example: Fetch Keycloak credentials  
KEYCLOAK_SECRET=$(aws secretsmanager get-secret-value --secret-id "keystone/dev/keycloak_admin" --query SecretString --output text)
KEYCLOAK_USERNAME=$(echo $KEYCLOAK_SECRET | jq -r '.username')
KEYCLOAK_PASSWORD=$(echo $KEYCLOAK_SECRET | jq -r '.password')
```

## Tech We Use

### Core Infrastructure
- **Terraform** - Infrastructure as Code with AWS provider
- **AWS VPC** - Virtual Private Cloud for network isolation
- **AWS EC2** - Compute instances and security groups
- **AWS S3** - Terraform state storage with encryption

### Security & Access Management
- **AWS Secrets Manager** - Secure credential storage and rotation
- **AWS IAM** - Identity and access management with roles and policies
- **AWS Security Groups** - Network-level security controls
- **AWS NAT Gateway** - Secure outbound internet access for private subnets

### Networking & Connectivity
- **AWS Internet Gateway** - Public internet connectivity
- **AWS Route Tables** - Network traffic routing configuration
- **AWS Elastic IP** - Static IP addresses for NAT Gateway
- **Multi-AZ Deployment** - High availability across availability zones

### Development & Operations
- **Git** - Version control and collaboration
- **AWS CLI** - Command-line interface for AWS services
- **jq** - JSON parsing and manipulation in scripts
- **Bash Scripting** - Automation and deployment utilities

### Monitoring & Validation
- **Terraform State** - Infrastructure state tracking and management
- **AWS CloudTrail** - API call logging and audit trails
- **Resource Tagging** - Comprehensive resource identification and cost allocation

## Features

### 🏗️ Infrastructure Architecture
- **Modular Design** - Reusable Terraform modules for VPC, security groups, secrets management, authentication ALB, and target groups
- **Multi-Environment Support** - Isolated configurations for dev, UAT, and production environments
- **High Availability** - Multi-AZ deployment with automated failover capabilities
- **Scalable Network Design** - Public and private subnets with proper routing and security
- **Authentication Load Balancing** - Dedicated ALB for Keycloak authentication service with health-checked target groups

### 🔐 Security & Compliance
- **Defense in Depth** - Layered security with ALB, web, and database security groups
- **Secrets Management** - AWS Secrets Manager integration with automatic password generation
- **IAM Best Practices** - Least-privilege access with role-based permissions
- **Network Isolation** - Private subnets for sensitive workloads with controlled internet access

### ☁️ AWS Integration
- **State Management** - S3 backend with encryption for Terraform state storage
- **Resource Tagging** - Comprehensive tagging strategy for cost allocation and management
- **ETL Pipeline Support** - Dedicated networking for Kimball ETL data processing workloads
- **Secrets Automation** - Automated credential generation and IAM role provisioning

### 🔄 DevOps & Automation
- **Environment Isolation** - Separate state files and configurations per environment
- **Password Generation** - Automated secure password creation for secrets
- **Infrastructure Validation** - Built-in validation and output verification
- **Deployment Scripts** - Automated deployment and configuration utilities

### 📊 Monitoring & Management
- **Output Management** - Comprehensive Terraform outputs for integration with other systems
- **Resource Mapping** - Clear mapping between logical and physical AWS resources
- **Cost Optimization** - Efficient resource allocation and environment-specific sizing
- **Infrastructure Documentation** - Self-documenting infrastructure with comprehensive outputs

## Architecture

### Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Kainam VPC (10.0.0.0/16)               │
├─────────────────────────────────────────────────────────────┤
│  Public Subnets (ALB Tier)                                 │
│  ┌─────────────────┐        ┌─────────────────┐           │
│  │ Public Subnet A │        │ Public Subnet B │           │
│  │  10.0.1.0/24   │        │  10.0.2.0/24   │           │
│  │  us-east-2a    │        │  us-east-2b    │           │
│  └─────────────────┘        └─────────────────┘           │
│            │                          │                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Internet Gateway                        │   │
│  └─────────────────────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│  Private Subnets (Application/Database Tier)               │
│  ┌─────────────────┐        ┌─────────────────┐           │
│  │Private Subnet A │        │Private Subnet B │           │
│  │ 10.0.101.0/24  │        │ 10.0.102.0/24  │           │
│  │  us-east-2a    │        │  us-east-2b    │           │
│  └─────────────────┘        └─────────────────┘           │
│            │                          │                   │
│  ┌─────────────────────────────────────────────────────┐   │
│  │               NAT Gateway                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Security Groups Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Groups                          │
├─────────────────────────────────────────────────────────────┤
│  ALB Security Group                                         │
│  • Ingress: HTTPS (443) from 0.0.0.0/0                    │
│  • Egress: All traffic to Web Security Group               │
│  • Egress: HTTP (8080) to Keycloak Security Group         │
├─────────────────────────────────────────────────────────────┤
│  Web Security Group                                         │
│  • Ingress: All traffic from ALB Security Group            │
│  • Ingress: SSH (22) from trusted IP ranges               │
│  • Egress: All traffic to 0.0.0.0/0                       │
├─────────────────────────────────────────────────────────────┤
│  Keycloak Security Group (Dedicated Authentication Tier)   │
│  • Ingress: HTTP (8080) from ALB Security Group           │
│  • Egress: All traffic to 0.0.0.0/0                       │
├─────────────────────────────────────────────────────────────┤
│  Database Security Group                                    │
│  • Ingress: PostgreSQL (5432) from Web Security Group     │
│  • Egress: All traffic to 0.0.0.0/0                       │
└─────────────────────────────────────────────────────────────┘
```

**Security Group Enhancements (2025-09-09):**
- **Service Isolation**: Keycloak now has a dedicated security group following least privilege principles
- **ALB-to-Keycloak Rule**: Direct egress rule from ALB to Keycloak SG (TCP:8080) for health checks and routing
- **Authentication Tier**: Separate security boundary for critical authentication infrastructure

**SSL Certificate Management (2025-09-10 - ISSUE-014):**
- **App Runner Certificate Validation**: Manual DNS validation process established for App Runner custom domains
- **Certificate Validation Records**: Two DNS validation records manually created in Route 53
- **State Management**: Terraform state cleaned up to reflect manual infrastructure changes
- **Process Documentation**: Complete resolution process documented for future SSL certificate issues

### Module Structure

```
infra-terraform/terraform/modules/
├── vpc/                          # Core networking infrastructure
│   ├── VPC with DNS resolution
│   ├── Public/Private subnets across AZs
│   ├── Internet Gateway & NAT Gateway
│   └── Route tables & associations
├── security-groups/              # Network security controls
│   ├── ALB security group (HTTPS ingress)
│   ├── Web security group (ALB + SSH access)
│   └── Database security group (PostgreSQL from web)
├── secrets-manager/              # Credential management
│   ├── Database credentials secret
│   ├── Keycloak admin credentials secret
│   └── IAM role & policy for EC2 access
├── auth-alb/                     # Authentication load balancer
│   ├── Internet-facing ALB for Keycloak
│   ├── HTTP/2 and security optimizations
│   └── Integration with target groups
├── target-groups/                # Load balancer target management
│   ├── Keycloak target group configuration
│   ├── Health check optimization
│   └── Connection draining settings
├── kimball-etl-networking/       # ETL pipeline networking
│    ├── ETL-specific subnets
│    ├── ETL security groups
│    └── External data source access controls
├── ecr/                          # Multi-service container registry management
│    ├── SENNA repositories (API, Frontend, Models)
│    ├── Kainam Platform repositories (API, Frontend)
│    ├── Keycloak authentication repository
│    ├── Dynamic service naming with configurable repository creation
│    ├── Lifecycle policies for automated image cleanup
│    └── CI/CD integration (GitHub Actions + CodePipeline)
├── elasticache/                  # Redis cluster management
│    ├── Redis 7.0 cluster configuration
│    ├── Parameter group with optimized settings
│    ├── Subnet group for VPC placement
│    └── Security group for access control
├── iam-roles/                    # Identity and access management
│    ├── GitHub Actions OIDC provider and role
│    ├── App Runner access and instance roles
│    ├── EC2 instance and worker roles
│    ├── Instance profiles for EC2 attachment
│    └── Scoped policies for least-privilege access
├── codepipeline/                 # CI/CD automation
│    ├── CodePipeline workflows for SENNA applications
│    ├── CodeBuild projects with inline buildspecs
│    ├── S3 artifacts bucket with encryption
│    ├── IAM service roles for pipeline execution
│    └── GitHub integration via CodeStar Connections
├── app-runner/                   # AWS App Runner managed container services
│    ├── App Runner service configuration with ECR integration
│    ├── VPC connector for internal resource access
│    ├── Security groups for egress traffic control
│    ├── Health check configuration (TCP/HTTP)
│    ├── Auto-scaling and deployment settings
│    └── Environment variable management
├── alb-listeners/                # ALB listener configuration
├── route53-records/              # DNS record management for authentication and SENNA services
│    ├── Authentication domain records (auth-dev.kainam.app)
│    ├── SENNA application domain records (senna-dev.kainam.app)  
│    ├── Certificate validation records for App Runner custom domains
│    └── Health check and routing configurations
├── rds/                          # RDS database management
│    ├── PostgreSQL instance for Keycloak
│    ├── Subnet and security groups
│    └── Parameter group for database settings
├── ec2-keycloak/                 # Keycloak authentication server
│    ├── EC2 instance in private subnet
│    ├── SSH key pair for maintenance access
│    ├── Security group with ALB integration
│    ├── IAM role with Session Manager permissions
│    ├── VPC endpoints for private subnet access
│    └── Target group attachment for ALB
```

## Current Infrastructure Status

### Deployed Modules (DEV Environment)

| Module | Status | Resources | Purpose |
|--------|--------|-----------|---------|
| **VPC** | ✅ Active | 8 resources | Core networking infrastructure |
| **Security Groups** | ✅ Active | 3 groups | Network access control |
| **Secrets Manager** | ✅ Active | 2 secrets + policy | Credential management |
| **IAM (Keystone)** | ✅ Active | 3 resources | EC2 secrets access |
| **ETL Networking** | ✅ Active | 8 resources | Kimball ETL network isolation |
| **Authentication ALB** | ✅ Active | 6 resources | Keycloak load balancing |
| **Target Groups** | ✅ Active | 1 target group | Health check routing |
| **DNS (Route 53)** | ✅ Active | 1 A record | Domain resolution |
| **ECR** | ✅ Active | 14 resources | Multi-service container registry (SENNA + Kainam Platform + Keycloak) |
| **ElastiCache** | ✅ Active | 4 resources | Redis replication group with SSL/TLS |
| **App Runner** | ✅ Active | 10 resources | SENNA + Kainam Platform managed container services with certificate validation |
| **IAM Roles (SENNA)** | ✅ Active | 13 resources | Multi-service access control |
| **CodePipeline** | ✅ Active | 27 resources | CI/CD automation (SENNA + Keycloak + Kainam Platform pipelines) |
| **EC2 Workers** | ✅ Active | 12 resources | SENNA ML models and Celery workers |
| **RDS** | ✅ Active | 5 resources | PostgreSQL database for Keycloak |
| **Keycloak EC2** | ✅ Active | 7 resources | Keycloak authentication server with Session Manager |
| **VPC Endpoints** | ✅ Active | 3 resources | Session Manager endpoints for private subnet access |

### Infrastructure Summary

**Total Resources Deployed:** 106 AWS resources across 18 modules  
**Environment:** Development (DEV)  
**Region:** us-east-2  
**Last Updated:** September 24, 2025  

**Key Capabilities:**
- ✅ **Secure Networking:** Multi-AZ VPC with public/private subnet isolation
- ✅ **Authentication Infrastructure:** ALB + Target Groups with deployed Keycloak service
- ✅ **Multi-Service Container Registry:** ECR repositories for SENNA, Kainam Platform, and Keycloak applications
- ✅ **Caching Layer:** Redis replication group with SSL/TLS encryption and authentication
- ✅ **App Runner Services:** SENNA + Kainam Platform services deployed and running with VPC integration, custom domains, and SSL certificate validation
- ✅ **Identity Management:** Comprehensive IAM roles for GitHub Actions, App Runner, and EC2
- ✅ **CI/CD Automation:** CodePipeline workflows for automated Docker builds and ECR deployments (SENNA + Keycloak + Kainam Platform)
- ✅ **Secrets Management:** AWS Secrets Manager with backend client secrets for Keycloak integration

**SENNA Application Status:** 🔄 **PLATFORM DEPLOYED - SSL VALIDATION IN PROGRESS**
- **SENNA Frontend:** 🔄 RUNNING (https://senna-dev.kainam.app) - SSL certificate validation in progress (ISSUE-014)
- **SENNA API Service:** ✅ RUNNING (https://wdtyf4qmpn.us-east-2.awsapprunner.com)
- **EC2 Workers:** ✅ RUNNING (i-0d58276b98aa3208e, SSH: ubuntu@3.128.205.241)
- **Redis ElastiCache:** ✅ Available with SSL/TLS encryption and authentication
- **CI/CD Pipelines:** ✅ All operational (API, Frontend, Models)
- **ECR Repositories:** ✅ Ready for container image deployments
- **SSL Certificate Validation:** 🔄 Manual DNS records created, validation completing (1 of 2 records validated)
- **Complete Infrastructure:** ✅ 99 AWS resources across 18 modules deployed

**Keycloak Authentication Status:** ✅ **FULLY OPERATIONAL AND CONFIGURED**
- **ECR Repository:** ✅ READY (`keycloak-ecr-dev`)
- **CI/CD Pipeline:** ✅ OPERATIONAL (`keycloak-cb-pipeline-dev`)
- **PostgreSQL RDS:** ✅ RUNNING (`kainam-dev-keycloak-db`)
- **ALB Infrastructure:** ✅ OPERATIONAL (`kainam-auth-dev-alb`)
- **EC2 Instance:** ✅ RUNNING (`i-0b53d307ca0b3c67e`, Private IP: 10.0.101.124)
- **SSH Access:** ✅ CONFIGURED (Session Manager via `ssh keycloak-dev`)
- **VPC Endpoints:** ✅ DEPLOYED (SSM, EC2Messages, SSMMessages)
- **Service Integration:** ✅ **OPERATIONAL** (Admin console accessible at `https://auth-dev.kainam.app/admin`)
- **Security Groups:** ✅ **ENHANCED** (Dedicated Keycloak SG with ALB connectivity rules - ISSUE-012 resolved)
- **Container Health:** ✅ **HEALTHY** (Docker health checks fixed - ISSUE-013 resolved)
- **Realm Configuration:** ✅ **COMPLETE** (kainam-dev realm with SENNA clients configured - KEY-28 completed)
- **Client Secrets:** ✅ **SECURED** (Backend client secret stored in AWS Secrets Manager)

## Developer Notes

### Environment-Specific Configurations

Each environment has its own configuration with the following differences:

| Component | Development | UAT | Production |
|-----------|------------|-----|------------|
| **VPC CIDR** | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| **Trusted IPs** | Empty (open) | Office/VPN ranges | Bastion host only |
| **ETL Access** | Allow all external | Restricted external | Highly restricted |
| **State Backend** | kainam-dev-tf-state | kainam-uat-tf-state | kainam-prod-tf-state |
| **Secrets** | Generated locally | AWS Secrets Manager | AWS Secrets Manager |

### Customization Guidelines

**Adding a new environment:**

1. Create new directory in `envs/`: `envs/staging/`
2. Copy `dev/main.tf` and modify the `locals` block
3. Update CIDR blocks, trusted IPs, and tags
4. Create new S3 bucket for state storage
5. Run `terraform init` and `terraform apply`

**Adding new modules:**

1. Create module directory in `modules/`
2. Define `variables.tf`, `main.tf`, and `outputs.tf`
3. Update root `main.tf` to include the module
4. Add outputs to root `outputs.tf`
5. Test in development environment first

**Security best practices:**

- Always use least-privilege IAM policies
- Never commit `secrets.tfvars` to version control
- Regularly rotate generated passwords
- Review security group rules for unnecessary access
- Use AWS Config for compliance monitoring

### Troubleshooting

**Common issues and solutions:**

```bash
# Issue: VPC quota exceeded
# Solution: Request quota increase or clean up unused VPCs
aws ec2 describe-vpcs --query "Vpcs[*].[VpcId,State,Tags[?Key=='Name'].Value|[0]]" --output table

# Issue: Terraform state locked
# Solution: Check for stuck processes or force unlock (use carefully)
terraform force-unlock <lock-id>

# Issue: Secrets access denied
# Solution: Verify EC2 instance has correct IAM role attached
aws sts assume-role --role-arn arn:aws:iam::ACCOUNT:role/keystone-ec2-role --role-session-name test
```

**Resource naming conventions:**

- **VPC**: `{project}-{environment}-vpc`
- **Subnets**: `{project}-{environment}-{type}-subnet-{az}`
- **Security Groups**: `{project}-{environment}-{tier}-sg`
- **Secrets**: `{project}/{environment}/{service}`
- **IAM Roles**: `{project}-{service}-role`

### Migration and Maintenance

**State management:**

```bash
# Backup current state
terraform state pull > backup.tfstate

# Move resources between states (if restructuring)
terraform state mv aws_vpc.old aws_vpc.new

# Import existing AWS resources
terraform import aws_vpc.main vpc-1234567890abcdef0
```

**Version management:**

- Keep Terraform version consistent across environments
- Test provider updates in development first
- Use version constraints in `versions.tf`
- Document any breaking changes in deployment notes

---

*This infrastructure provides a solid foundation for the Kainam Platform, supporting scalable authentication services, secure data processing pipelines, and multi-environment deployment strategies with enterprise-grade security and compliance.*
