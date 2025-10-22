# [TECH DEBT & SECURITY REPORT] :: Keystone RBAC

**Date:** 2025-01-31  
**Owner:** Orchestrator
**Last Updated:** 2025-01-31 (Added CERT-DEBT-001 based on ISSUE-010 findings)

## CRITICAL SECURITY ISSUES (Must be fixed before Production)

| ID                  | Issue Description                 | Risk                                             | Required Action (Links to Task) |
|---------------------|-----------------------------------|--------------------------------------------------|---------------------------------|
| **SEC-DEBT-001** | Insecure Cookie Configuration     | Cookies transmitted over unencrypted HTTP.       | Set `--cookie-secure=true` during [KEY-8] |
| **SEC-DEBT-002** | Unverified Email Bypass           | Allows authentication with unverified emails.    | Remove flag, enforce email verification. |
| **SEC-DEBT-003** | CA Verification Disabled        | Susceptible to Man-in-the-Middle attacks.        | Remove flag, use proper SSL certs. |
| **SEC-DEBT-004** | Weak Default Credentials        | Easy credential guessing, unauthorized access.   | Migrate to AWS Secrets Manager ([KEY-9]) |
| **SEC-DEBT-005** | Placeholder Client Secret       | Non-functional or insecure authentication.       | Generate strong secret for Keycloak client. |
| **SEC-DEBT-006** | Unencrypted HTTP Communication    | Credentials and tokens transmitted in plaintext. | Implement ALB with HTTPS/TLS ([KEY-8]) |
| **SEC-DEBT-007** | Hardcoded IP Addresses            | Configuration breaks when instances change.      | Use DNS and service discovery. |
| **INFRA-DEBT-001** | No Terraform State Locking      | Multiple concurrent Terraform runs could corrupt state. | Implement DynamoDB table for state locking. |

## CONFIGURATION MANAGEMENT DEBT (CRITICAL - High Priority)

| ID                  | Issue Description                 | Priority | Required Action |
|---------------------|-----------------------------------|----------|-----------------|
| **CONFIG-DEBT-001** | Configuration Chaos Across Environments | **CRITICAL** | Implement standardized configuration management strategy with environment-specific files |
| **CONFIG-DEBT-002** | Port/Service Name Inconsistency    | **CRITICAL** | Standardize all service names, ports, and parameters across environments (only URLs should vary) |
| **CONFIG-DEBT-003** | Docker Compose File Proliferation  | HIGH     | Create organized environment-specific Docker Compose structure with clear naming conventions |
| **CONFIG-DEBT-004** | NGINX Configuration Drift         | HIGH     | Implement environment-specific NGINX configurations with standardized upstream naming |
| **CONFIG-DEBT-005** | Environment Variable Chaos        | HIGH     | Consolidate and standardize environment variable names and structure across all environments |

### CONFIG-DEBT-001 Details: Configuration Chaos Across Environments

**Problem Evidence (Sprint 2 Issues):**
- **ISSUE-007**: OAuth2 configuration mismatch required updates in 3 different places
- **ISSUE-008**: Port inconsistency between local (3000) and EC2 (3001) environments
- **ISSUE-009**: URL format differences (`:80` vs no port) between environments

**Current Problematic State:**
- `local.env` vs `ec2.env` vs `.env` files with different structures
- `docker-compose-local.yml` vs `docker-compose.yml` with different port strategies
- `nginx-local.conf` vs `nginx.conf` with different upstream configurations
- Hardcoded environment-specific values scattered across multiple files

**Target Solution Architecture:**
```
authentication/
├── config/
│   ├── environments/
│   │   ├── local/
│   │   │   ├── docker-compose.yml
│   │   │   ├── nginx.conf
│   │   │   └── .env
│   │   ├── staging/
│   │   │   ├── docker-compose.yml
│   │   │   ├── nginx.conf
│   │   │   └── .env
│   │   └── production/
│   │       ├── docker-compose.yml
│   │       ├── nginx.conf
│   │       └── .env
│   └── shared/
│       ├── docker-compose.base.yml
│       ├── nginx.base.conf
│       └── service-defaults.env
```

### CONFIG-DEBT-002 Details: Service Standardization Requirements

**Standardization Rules (MUST BE IDENTICAL across environments):**
- **Service Names**: `keystone-backend`, `keystone-frontend`, `keystone-nginx`, etc.
- **Internal Ports**: Backend always 8000, Frontend always 3000, OAuth2-proxy always 4180
- **Container Names**: Consistent naming pattern across all environments
- **Network Names**: `keystone-net` in all environments
- **Volume Names**: Standardized volume naming conventions

**Only Environment Variables (URLs/URIs should vary):**
- `BASE_URL` (http://localhost vs http://18.191.64.107:81)
- `OAUTH2_PROXY_OIDC_ISSUER_URL`
- `OAUTH2_PROXY_REDIRECT_URL`
- `NEXT_PUBLIC_OAUTH2_PROXY_URL`

### CONFIG-DEBT-003 Details: Docker Compose Organization Strategy

**Current Problematic Files:**
- `docker-compose-local.yml` - Local development
- `docker-compose.yml` - Production/EC2
- `docker-compose-ec2.yml` - Legacy EC2 (deprecated)

**Target Organized Structure:**
- `config/environments/local/docker-compose.yml` - Local development
- `config/environments/staging/docker-compose.yml` - Staging environment
- `config/environments/production/docker-compose.yml` - Production environment
- `config/shared/docker-compose.base.yml` - Shared service definitions

**Benefits:**
- Clear environment separation
- Shared base configurations to reduce duplication
- Easy to add new environments (dev, staging, prod)
- Environment-specific overrides clearly isolated

### CONFIG-DEBT-004 Details: NGINX Configuration Standardization

**Current Issues:**
- `nginx-local.conf` uses `keystone-frontend:3000`
- `nginx.conf` (EC2) uses `keystone-frontend:3001`
- Different proxy buffer settings between environments

**Target Standardization:**
- **Upstream Names**: Identical across environments (`keystone-frontend:3000`)
- **Service Ports**: Standardized internal ports (frontend always 3000)
- **Location Blocks**: Identical routing logic
- **Only Environment Variables**: `BACKEND_HOST`, `FRONTEND_HOST`, `OAUTH2_HOST`

### CONFIG-DEBT-005 Details: Environment Variable Chaos

**Current Problems:**
- Inconsistent variable names (`NEXT_PUBLIC_OAUTH2_PROXY_URL` vs `OAUTH2_PROXY_URL`)
- Different variable structures between environments
- Hardcoded URLs mixed with configurable URLs
- No clear separation between infrastructure and application variables

**Target Variable Structure:**
```bash
# Infrastructure Variables (environment-specific)
BASE_URL=http://localhost                    # or http://18.191.64.107:81
EXTERNAL_PORT=80                            # or 81
ENVIRONMENT=local                           # or staging, production

# Service URLs (derived from BASE_URL)
OAUTH2_PROXY_OIDC_ISSUER_URL=${BASE_URL}/realms/keystone-mvp
OAUTH2_PROXY_REDIRECT_URL=${BASE_URL}/oauth2/callback
NEXT_PUBLIC_OAUTH2_PROXY_URL=${BASE_URL}/oauth2/start

# Internal Service Configuration (identical across environments)
POSTGRES_DB=keycloak
KEYCLOAK_REALM=keystone-mvp
OAUTH2_PROXY_CLIENT_ID=keystone-frontend
```

## IMPLEMENTATION STRATEGY: Configuration Management Refactoring

### Phase 1: File Organization (Priority: CRITICAL)
**Goal**: Organize configuration files into clear environment-specific structure

**Tasks:**
1. **Create Environment Directory Structure**:
   ```
   authentication/config/
   ├── environments/
   │   ├── local/
   │   ├── staging/  
   │   └── production/
   └── shared/
   ```

2. **Migrate Existing Files**:
   - `docker-compose-local.yml` → `config/environments/local/docker-compose.yml`
   - `docker-compose.yml` → `config/environments/production/docker-compose.yml`
   - `nginx-local.conf` → `config/environments/local/nginx.conf`
   - `nginx.conf` → `config/environments/production/nginx.conf`
   - `local.env` → `config/environments/local/.env`
   - `ec2.env` → `config/environments/production/.env`

3. **Create Shared Base Files**:
   - `config/shared/docker-compose.base.yml` - Common service definitions
   - `config/shared/nginx.base.conf` - Common NGINX blocks
   - `config/shared/service-defaults.env` - Default service configuration

### Phase 2: Service Standardization (Priority: CRITICAL)
**Goal**: Ensure identical service names, ports, and container configurations

**Standardization Requirements:**
- **Service Names**: Always `keystone-{service}` format
- **Internal Ports**: Backend=8000, Frontend=3000, OAuth2-proxy=4180, Keycloak=8080
- **Container Names**: Match service names exactly
- **Network**: Always `keystone-net`
- **Volume Naming**: `keystone-{service}-{purpose}` format

### Phase 3: NGINX Template System (Priority: HIGH)
**Goal**: Single NGINX configuration with environment variable substitution

**Implementation:**
1. **Create NGINX Template**: `config/shared/nginx.template.conf`
2. **Environment Variables**: `${BACKEND_HOST}`, `${FRONTEND_HOST}`, etc.
3. **Build-time Substitution**: Use `envsubst` to generate environment-specific configs
4. **Identical Logic**: Same location blocks, same upstream logic, only hosts vary

### Phase 4: Environment Variable Standardization (Priority: HIGH)
**Goal**: Consistent, predictable environment variable structure

**Rules:**
- **Single Source of Truth**: One `BASE_URL` per environment
- **Derived Variables**: All service URLs computed from `BASE_URL`
- **Consistent Naming**: Standard prefixes (`OAUTH2_PROXY_`, `NEXT_PUBLIC_`)
- **Clear Separation**: Infrastructure vs application vs secrets

### Phase 5: Deployment Script Integration (Priority: MEDIUM)
**Goal**: Automated environment selection and deployment

**Scripts:**
- `scripts/deploy.sh [local|staging|production]` - Environment-aware deployment
- `scripts/setup-environment.sh` - Generate environment-specific configs from templates
- `scripts/validate-config.sh` - Verify configuration consistency across environments

### Benefits of This Approach:
✅ **Eliminates Configuration Drift**: Identical services across environments
✅ **Reduces Sprint 2-type Issues**: Standardized ports prevent mismatch problems  
✅ **Simplifies Debugging**: Predictable configuration structure
✅ **Enables Easy Environment Addition**: Clear template for new environments
✅ **Improves Maintainability**: Single source of truth for configuration logic
✅ **Reduces Human Error**: Automated config generation from templates

## CERTIFICATE & DOMAIN MANAGEMENT DEBT (HIGH Priority)

| ID                  | Issue Description                 | Priority | Required Action |
|---------------------|-----------------------------------|----------|-----------------|
| **CERT-DEBT-001** | Inconsistent Domain Strategy and Certificate Coverage | **HIGH** | Standardize Environment Subdomains and Certificates |

### CERT-DEBT-001 Details: Standardize Environment Subdomains and Certificates

**Problem Evidence (from ISSUE-010):**
- Current workaround uses `auth-dev.kainam.app` due to wildcard certificate `*.kainam.app` limitations
- Wildcard certificates only cover single-level subdomains, not multi-level (e.g., `service.environment.domain.com`)
- Inconsistent domain strategy across services creates certificate management complexity
- Current domain pattern conflicts with intended architecture of `service.environment.kainam.app`

**Current Problematic State:**
- **Auth Service**: `auth-dev.kainam.app` (workaround due to certificate limitations)
- **SENNA Application**: TBD, but likely to face same certificate issues
- **Certificate**: Single `*.kainam.app` wildcard covering only first-level subdomains
- **Domain Strategy**: Inconsistent between intended (`service.environment.domain`) and actual (`service-environment.domain`)

**Target Solution Architecture:**
```
Domain Strategy: service.environment.kainam.app
├── dev.kainam.app (environment-specific)
│   ├── auth.dev.kainam.app
│   ├── senna.dev.kainam.app
│   └── kimball.dev.kainam.app
├── staging.kainam.app
│   ├── auth.staging.kainam.app
│   └── senna.staging.kainam.app
└── kainam.app (production)
    ├── auth.kainam.app
    └── senna.kainam.app
```

**Certificate Architecture:**
- **DEV Environment**: `*.dev.kainam.app` wildcard certificate
- **STAGING Environment**: `*.staging.kainam.app` wildcard certificate
- **PRODUCTION Environment**: `*.kainam.app` wildcard certificate (existing)

**Story Points**: 3

**Acceptance Criteria:**
- ✅ A new ACM certificate for `*.dev.kainam.app` is provisioned and validated
- ✅ The Terraform configuration for the dev environment is updated to use this new certificate for all public-facing services (e.g., ALB listeners)
- ✅ The Central Auth Service domain is reverted to `auth.dev.kainam.app`
- ✅ The SENNA Application domain is configured as `senna.dev.kainam.app`
- ✅ Project documentation is updated to reflect this as the official naming convention

**Implementation Strategy:**
1. **Certificate Provisioning**: Request and validate new `*.dev.kainam.app` ACM certificate
2. **Terraform Updates**: Update DEV environment configuration to reference new certificate ARN
3. **DNS Migration**: Update Route53 records to use proper `service.environment.domain` format
4. **Documentation**: Update all project documentation to reflect standardized domain strategy
5. **Validation**: Ensure all services work correctly with new domain structure

**Benefits:**
- ✅ **Consistent Domain Strategy**: All services follow `service.environment.domain` pattern
- ✅ **Proper Certificate Coverage**: Environment-specific certificates eliminate workarounds
- ✅ **Scalable Architecture**: Easy to add new services and environments
- ✅ **Eliminates Future Certificate Issues**: No more RFC 6125 wildcard limitations
- ✅ **Professional Domain Structure**: Clear separation between environments and services

**Risk Mitigation:**
- DNS propagation time may cause temporary service interruptions during migration
- Certificate validation process may take up to 30 minutes
- Need to update all environment variables and configurations referencing old domains

### DOCKER-DEBT-001 Details: Keycloak Container Health Check Failure

**Problem Evidence (from ISSUE-011):**
- Docker health check fails with: `"/bin/sh: line 1: curl: command not found"`
- Container status shows "unhealthy" despite Keycloak service being fully operational
- Health check command: `curl -f http://localhost:8080/health/ready || exit 1`

**Current Problematic State:**
- Keycloak container uses Red Hat Enterprise Linux 9.6 base image
- Base image does not include curl utility required for health checks
- Bootstrap script attempts to install curl via `microdnf` but command is not available
- Docker health monitoring is non-functional, affecting deployment visibility

**Target Solution Architecture:**
```dockerfile
# Create custom Keycloak image with curl
FROM quay.io/keycloak/keycloak:26.3.2
USER root
RUN microdnf install -y curl || dnf install -y curl || yum install -y curl
USER 1000
```

**Implementation Strategy:**
1. **Custom Dockerfile**: Create Keycloak image with curl pre-installed
2. **ECR Integration**: Build and push custom image to ECR repository  
3. **Bootstrap Script Update**: Reference custom image instead of official image
4. **Health Check Validation**: Verify health endpoints work with curl
5. **CI/CD Integration**: Automate custom image builds in deployment pipeline

**Benefits:**
- ✅ **Proper Health Monitoring**: Docker health checks work correctly
- ✅ **Deployment Visibility**: Container status accurately reflects service health
- ✅ **Production Readiness**: Proper health monitoring for load balancers and orchestrators
- ✅ **Debugging Capability**: curl available for troubleshooting within container

### CONFIG-DEBT-006 Details: Deprecated Keycloak Environment Variables

**Problem Evidence (from ISSUE-011):**
- Keycloak startup logs show deprecation warnings:
  ```
  WARN KC-SERVICES0110: Environment variable 'KEYCLOAK_ADMIN' is deprecated, use 'KC_BOOTSTRAP_ADMIN_USERNAME' instead
  WARN KC-SERVICES0110: Environment variable 'KEYCLOAK_ADMIN_PASSWORD' is deprecated, use 'KC_BOOTSTRAP_ADMIN_PASSWORD' instead
  ```

**Current Configuration (Deprecated):**
```bash
-e KEYCLOAK_ADMIN="keycloak_admin"
-e KEYCLOAK_ADMIN_PASSWORD="<password-from-secrets-manager>"
```

**Target Configuration (Current):**
```bash
-e KC_BOOTSTRAP_ADMIN_USERNAME="keycloak_admin"
-e KC_BOOTSTRAP_ADMIN_PASSWORD="<password-from-secrets-manager>"
```

**Implementation Strategy:**
1. **Bootstrap Script Update**: Replace deprecated environment variables
2. **Testing Validation**: Verify admin user creation works with new variables
3. **Documentation Update**: Update deployment documentation with new variable names

**Story Points**: 1

**Acceptance Criteria:**
- ✅ Bootstrap script uses KC_BOOTSTRAP_ADMIN_USERNAME and KC_BOOTSTRAP_ADMIN_PASSWORD
- ✅ No deprecation warnings in Keycloak startup logs
- ✅ Admin user creation continues to work correctly
- ✅ Documentation updated to reflect new variable names

**Risk Mitigation:**
- Low risk change - both old and new variables work in current Keycloak version
- Backward compatibility maintained during transition period

## EC2 DEPLOYMENT & AUTOMATION DEBT

| ID                  | Issue Description                 | Priority | Required Action |
|---------------------|-----------------------------------|----------|-----------------|
| **EC2-DEBT-001** | Manual EC2 Instance Management     | HIGH     | Create Terraform script to provision EC2 instance for auth system deployment |
| **EC2-DEBT-002** | Manual EC2 Environment Setup       | HIGH     | Create automated script to install Docker, AWS CLI, and all required dependencies on EC2 |
| **EC2-DEBT-003** | Manual SSL Deactivation Process    | MEDIUM   | Create script to automate Keycloak SSL requirement deactivation (`kcadm.sh` commands) |
| **EC2-DEBT-004** | Manual Keycloak Realm Configuration | MEDIUM   | Create script to automate Keycloak realm setup and client configuration |
| **EC2-DEBT-005** | No CI/CD Pipeline                  | HIGH     | Create Terraform script for CI/CD pipeline: ECR → EC2 deployment automation |
| **EC2-DEBT-006** | Insufficient EC2 IAM Permissions   | HIGH     | Enhance `keystone-ec2-role` with EC2 toolkit permissions + comprehensive secrets access |
| **EC2-DEBT-007** | IAM Role Architecture Strategy      | MEDIUM   | Define modular strategy for IAM role placement in Terraform modules (centralized vs distributed) |
| **EC2-DEBT-008** | Keycloak Gateway Architecture Inconsistency | MEDIUM | Implement single NGINX gateway for ALL traffic including Keycloak (currently uses direct access pattern) |
| **EC2-DEBT-009** | EC2 Module Architecture Strategy | HIGH | Create shared EC2 base template and dedicated service-specific modules to reduce code duplication |
| **EC2-DEBT-010** | Missing Bootstrap Script Testing | HIGH | Implement automated testing for bootstrap scripts before deployment to prevent runtime failures |
| **DOCKER-DEBT-001** | Keycloak Container Health Check Failure | RESOLVED | ✅ RESOLVED 2025-09-09: Updated Dockerfile health check to use wget instead of curl (ISSUE-013 fix) |
| **CONFIG-DEBT-006** | Deprecated Keycloak Environment Variables | RESOLVED | ✅ RESOLVED 2025-09-09: Updated all deployment configs to use KC_BOOTSTRAP_ADMIN_USERNAME/PASSWORD (ISSUE-013 fix) |

### EC2-DEBT-006 Details: Enhanced IAM Role Requirements
**Current Role:** `keystone-ec2-role` (basic secrets access only)
**Required Enhancements:**
- EC2 describe/manage permissions for self-management
- ECR pull permissions for container deployments  
- CloudWatch logs permissions for monitoring
- Systems Manager permissions for configuration management
- Enhanced Secrets Manager permissions (List, Describe, GetValue)

### EC2-DEBT-007 Details: IAM Module Architecture Decision
**Current State:** IAM role embedded in `secrets-manager` module
**Strategic Options:**
1. **Centralized IAM Module:** Dedicated `/modules/iam/` with role definitions
2. **Distributed IAM:** Each module manages its own IAM resources
3. **Hybrid Approach:** Core roles centralized, feature-specific roles distributed

**Recommendation:** Requires architectural decision based on team preferences and scalability requirements.

### EC2-DEBT-009 Details: EC2 Module Architecture Strategy
**Problem:** Current EC2 modules have code duplication and inconsistent patterns
**Current State:** 
- `ec2-senna-models` module for ML workloads
- Need for `ec2-keycloak` module for authentication service
- Potential for future EC2 modules with duplicated code

**Target Architecture Strategy:**
```
infra-terraform/terraform/modules/
├── ec2-base/                    # Shared EC2 base template
│   ├── main.tf                  # Common EC2 resources (instance, security groups, IAM)
│   ├── variables.tf             # Standard EC2 variables
│   └── outputs.tf               # Standard EC2 outputs
├── ec2-senna-models/            # SENNA ML workloads (uses ec2-base)
├── ec2-keycloak/                # Keycloak authentication (uses ec2-base)
└── ec2-{future-service}/        # Future services (uses ec2-base)
```

**Implementation Strategy:**
1. **Server Separation**: Each service type maintains its own dedicated EC2 module
2. **Base Template**: Shared `ec2-base` module to reduce code duplication
3. **Service-Specific Configuration**: Each module extends base with service-specific needs
4. **Environment Strategy**: Consistent EC2 instance management across all services

**Benefits:**
- ✅ **Separation of Concerns**: Each service has dedicated, maintainable module
- ✅ **Code Reusability**: Shared base template eliminates duplication
- ✅ **Consistency**: Standardized EC2 patterns across all services
- ✅ **Scalability**: Easy to add new EC2-based services
- ✅ **Maintainability**: Changes to base template benefit all services

**Story Points**: 5

**Acceptance Criteria:**
- ✅ `ec2-base` module created with reusable EC2 components
- ✅ `ec2-keycloak` module created using `ec2-base` foundation
- ✅ Existing `ec2-senna-models` refactored to use `ec2-base` (future task)
- ✅ Documentation updated with EC2 module architecture strategy
- ✅ All EC2 modules follow consistent naming and structure patterns

### EC2-DEBT-008 Details: NGINX Gateway Architecture Inconsistency
**Current EC2 Implementation:** Mixed gateway pattern with direct Keycloak access
**Target Architecture:** Single NGINX gateway as the sole entry point for all services

**Current State:**
- NGINX Gateway on port 81 (for OAuth2-proxy, frontend, backend)
- Keycloak direct access on port 80 (bypasses gateway)
- OAuth2-proxy URLs point to port 80 for Keycloak endpoints

**Target Architecture (from design):**
- Single NGINX gateway on port 81 for ALL traffic including Keycloak
- All external access routed through NGINX with proper `/realms/` and `/admin/` routing
- Unified entry point aligning with "Gateway / Edge Layer" design

**Migration Required:**
1. Add Keycloak routing blocks to NGINX configuration
2. Update environment variables to use port 81 for all Keycloak URLs
3. Remove direct Keycloak port exposure
4. Ensure proper `X-Forwarded-Port` header handling for OIDC URL generation

## CI/CD PIPELINE ARCHITECTURE DEBT (MEDIUM Priority)

| ID                  | Issue Description                 | Priority | Required Action |
|---------------------|-----------------------------------|----------|-----------------|
| **CICD-DEBT-001** | CodePipeline to GitHub Actions Migration | **MEDIUM** | Migrate from AWS CodePipeline to GitHub Actions for better developer experience |

### CICD-DEBT-001 Details: CodePipeline to GitHub Actions Migration

**Current State:**
- Using AWS CodePipeline with CodeBuild for SENNA CI/CD automation
- Pipelines: `senna-front-cb-pipeline-dev`, `senna-models-cb-pipeline-dev`, `senna-api-cb-pipeline-dev`
- Triggers on DEV branch pushes to respective GitHub repositories
- AWS-native integration with ECR and IAM roles

**Target Architecture:**
- Migrate to GitHub Actions workflows for improved developer experience
- Utilize GitHub OIDC provider and IAM roles already deployed
- Direct integration with ECR using GitHub Actions marketplace actions
- Faster feedback loops and better integration with GitHub ecosystem

**Benefits of Migration:**
- ✅ **Developer Experience**: Workflows visible in GitHub repository interface
- ✅ **Faster Execution**: Reduced cold start times compared to CodeBuild
- ✅ **Better Integration**: Native GitHub features (PR checks, status badges)
- ✅ **Cost Optimization**: GitHub Actions included in GitHub plans
- ✅ **Ecosystem**: Rich marketplace of pre-built actions

**Migration Strategy:**
1. **Phase 1**: Create GitHub Actions workflows alongside existing CodePipeline
2. **Phase 2**: Test and validate GitHub Actions workflows
3. **Phase 3**: Switch triggers to GitHub Actions and deprecate CodePipeline
4. **Phase 4**: Remove CodePipeline resources and update documentation

**Story Points**: 3

**Acceptance Criteria:**
- ✅ GitHub Actions workflows created for all 3 SENNA repositories
- ✅ OIDC authentication working with existing IAM roles
- ✅ ECR push functionality equivalent to CodePipeline
- ✅ Proper branch triggers and workflow permissions configured
- ✅ CodePipeline resources cleanly removed after migration validation

**Risk Mitigation:**
- Keep CodePipeline active during transition period
- Thorough testing of GitHub Actions before switching
- Rollback plan to revert to CodePipeline if issues arise