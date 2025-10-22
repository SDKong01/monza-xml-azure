# Keycloak Deployment Plan - Task KEY-26-EC2-KEYCLOAK

## Overview

This document outlines the complete execution plan for deploying Keycloak on EC2 infrastructure using Terraform, Docker, and AWS CodeBuild CI/CD pipeline. The deployment follows a secure, automated, and maintainable approach aligned with AWS and Docker best practices.

## Execution Plan

### **Stage 1: Refactor Local Docker Environment & Define Docker Image Strategy**

#### **Action 1.1: Update docker-compose.yml**
- **File**: `authentication/docker-compose.yml`
- **Changes**:
  - Remove local `db`, `oauth2-proxy`, and `nginx` services
  - Comment out `frontend` and `backend` services for later integration
  - Reconfigure `keycloak` service to:
    - Connect to external RDS via environment variables
    - Set `KC_PROXY=edge` for ALB integration
    - Use port `8080:8080` mapping
    - Remove network dependencies

#### **Action 1.2: Create Multi-Stage Dockerfile**
- **File**: `authentication/Dockerfile`
- **Build Stage**:
  ```dockerfile
  FROM quay.io/keycloak/keycloak:26.3.2 AS builder
  # Set static build-time configuration
  ENV KC_DB=postgres
  ENV KC_HEALTH_ENABLED=true
  ENV KC_METRICS_ENABLED=true
  # Pre-optimize the server
  RUN /opt/keycloak/bin/kc.sh build
  ```
- **Runtime Stage**:
  ```dockerfile
  FROM quay.io/keycloak/keycloak:26.3.2
  COPY --from=builder /opt/keycloak/ /opt/keycloak/
  ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
  CMD ["start", "--optimized"]
  ```

### **Stage 2: Create CI/CD Pipeline for Authentication App**

#### **Pipeline Configuration**
- **Pipeline Name**: `keycloak-cb-pipeline-dev`
- **Source**: GitHub repository `kainam-backend`
- **Branch Filter**: `main`, `develop`, `aa-keystone`
- **Target ECR Repository**: `keycloak-ecr-dev`

#### **Buildspec with Monorepo Path Filtering**
```yaml
version: 0.2
phases:
  pre_build:
    commands:
      # Monorepo path filtering - only proceed if authentication files changed
      - |
        if git diff --name-only HEAD~1 HEAD | grep -E '^authentication/'; then
          echo "Authentication files changed, proceeding with build"
        else
          echo "No authentication files changed, skipping build"
          exit 0
        fi
      # ECR login
      - aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $ECR_REGISTRY
  build:
    commands:
      - cd authentication
      - docker build -t $ECR_REGISTRY/keycloak-ecr-dev:$CODEBUILD_RESOLVED_SOURCE_VERSION .
      - docker tag $ECR_REGISTRY/keycloak-ecr-dev:$CODEBUILD_RESOLVED_SOURCE_VERSION $ECR_REGISTRY/keycloak-ecr-dev:latest
  post_build:
    commands:
      - docker push $ECR_REGISTRY/keycloak-ecr-dev:$CODEBUILD_RESOLVED_SOURCE_VERSION
      - docker push $ECR_REGISTRY/keycloak-ecr-dev:latest
```

#### **Monitored Paths**
- `authentication/**` (all authentication-related files)
- `authentication/Dockerfile`
- `authentication/docker-compose.yml`
- `authentication/scripts/`

### **Stage 3: Create the Container Registry**

#### **ECR Repository Creation**
- **Action**: Extend existing `ecr` Terraform module
- **Repository Name**: `keycloak-ecr-dev`
- **Module Location**: `infra-terraform/terraform/modules/ecr/`
- **Configuration**:
  - Image scanning enabled
  - Lifecycle policy for image retention
  - IAM policies for CodeBuild access

### **Stage 4: Create the Automated Deployment Script**

#### **Script Template Creation**
- **File**: `authentication/scripts/deploy_keycloak.sh.tpl`
- **Functionality**:
  1. **Install Tools**: Docker, Docker Compose, AWS CLI (from `setup_instance.sh`)
  2. **Authenticate & Pull**: ECR login and pull `keycloak-ecr-dev:latest`
  3. **Container Management**: Stop/remove existing containers (from `deploy_models.sh`)
  4. **Fetch Secrets**: Retrieve credentials from Secrets Manager (from `fetch_secrets.sh`)
  5. **Run Keycloak**: Start container with runtime environment variables

#### **Runtime Environment Variables**
```bash
docker run -d --name keycloak \
  -p 8080:8080 \
  -e KC_HOSTNAME=${KC_HOSTNAME} \
  -e KC_DB_URL_HOST=${RDS_ENDPOINT} \
  -e KC_DB_URL_DATABASE=${DB_NAME} \
  -e KC_DB_USERNAME=${DB_USERNAME} \
  -e KC_DB_PASSWORD=${DB_PASSWORD} \
  -e KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN} \
  -e KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD} \
  -e KC_PROXY=edge \
  ${ECR_REGISTRY}/keycloak-ecr-dev:latest
```

### **Stage 5: Provision the EC2 Instance and Supporting Infrastructure**

#### **EC2 Instance Configuration**
- **Instance Type**: `t3.medium`
- **AMI**: `ami-0cfde0ea8edd312d4` (Ubuntu 22.04 LTS)
- **Subnet**: Private subnet (from `module.vpc.private_subnet_ids[0]`)
- **Public IP**: None (private subnet deployment)

#### **IAM Role and Policies**
- **Role Name**: `keycloak-ec2-role-dev`
- **Permissions**:
  - Read access to Secrets Manager secrets:
    - `keystone/dev/database`
    - `keystone/dev/keycloak_admin`
  - Pull access to ECR repository `keycloak-ecr-dev`
  - Basic EC2 instance permissions

#### **Security Group Configuration**
- **Security Group Name**: `keycloak-sg-app-dev`
- **Ingress Rules**:
  - Port 8080/TCP from ALB security group only
- **Egress Rules**:
  - All outbound traffic (for package updates, ECR pulls)

#### **User Data Integration**
- Terraform renders `deploy_keycloak.sh.tpl` with dynamic values:
  - RDS endpoint from `module.rds.db_instance_endpoint`
  - ECR repository URL
  - Database name and other configuration
- Rendered script passed to EC2 `user_data` parameter

### **Stage 6: Integrate with the Load Balancer**

#### **Target Group Registration**
- **Action**: Update `target-groups` module call in `dev/main.tf`
- **Configuration**:
  - Register EC2 instance ID with existing Keycloak target group
  - Health check path: `/health/ready`
  - Health check port: 8080
  - Health check protocol: HTTP

#### **ALB Integration**
- Traffic flow: Internet → ALB (port 443) → EC2 (port 8080) → Keycloak container
- SSL termination at ALB level
- Keycloak configured with `KC_PROXY=edge` for proper header handling

## Key Technical Decisions

### **Environment Variable Strategy**
- **Build Time**: Static configuration only (database type, features)
- **Runtime**: All dynamic configuration (hostnames, endpoints, credentials)

### **Security Architecture**
- **Network**: Private subnet deployment, no direct internet access
- **IAM**: Least-privilege roles with specific resource ARNs
- **Secrets**: Runtime fetching from AWS Secrets Manager
- **Container**: No sensitive data baked into images

### **CI/CD Optimization**
- **Monorepo Support**: Path-based filtering to avoid unnecessary builds
- **Build Efficiency**: Multi-stage Docker builds for optimized images
- **Deployment**: Automated via Terraform user_data

### **Infrastructure as Code**
- **Modularity**: Reusable Terraform modules
- **Environment Isolation**: Dev-specific configurations
- **State Management**: Remote state with locking

## Acceptance Criteria

1. **EC2 Instance**: Running and passing status checks in private subnet
2. **Keycloak Container**: Running and connected to PostgreSQL RDS database
3. **ALB Integration**: Health checks passing, traffic routing correctly
4. **Security**: No direct internet access, secrets managed securely
5. **CI/CD**: Pipeline triggers only on authentication file changes
6. **Automation**: Full deployment via Terraform with no manual steps

## Next Steps

After successful deployment:
1. Configure Keycloak realm and clients (KEY-28)
2. Integrate with SENNA API authentication
3. Set up monitoring and alerting
4. Plan for production deployment scaling

## Dependencies

- PostgreSQL RDS instance (KEY-31-KEYCLOAK-DB) - ✅ COMPLETED
- ALB and target groups infrastructure - ✅ EXISTING
- VPC and networking infrastructure - ✅ EXISTING
- Secrets Manager configuration - ✅ EXISTING

## Risks and Mitigations

1. **Container Startup Issues**: Pre-optimized image reduces startup time
2. **Secret Access**: IAM role testing before deployment
3. **Network Connectivity**: Security group validation
4. **Build Failures**: Path filtering prevents unnecessary pipeline runs
5. **Database Connection**: Connection string validation in deployment script
