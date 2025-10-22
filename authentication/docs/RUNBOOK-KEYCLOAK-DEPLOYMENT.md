# Keycloak Service Deployment Runbook - DEV Environment

**Version:** 2.0
**Last Updated:** 2025-09-10
**Owner:** DevOps Team
**Environment:** Development

---

## 📋 Overview

This runbook provides step-by-step instructions for deploying the Keycloak authentication service on AWS for the **DEV environment**. The deployment consists of several phases, from provisioning the database to configuring the Keycloak application.

**Deployment Status**: ✅ **COMPLETE** - All phases deployed and operational with realm configuration.

## 🎯 Prerequisites

### Required Tools
- **Terraform** v1.0+ with AWS provider v5.0+
- **AWS CLI** v2 configured with appropriate credentials
- **SSH Client** for accessing the EC2 instance

### Required Permissions
- EC2, RDS, VPC, IAM, Secrets Manager, ELB management permissions
- Route 53 DNS management (already configured)

### Environment Setup
```bash
# Navigate to the infrastructure directory for the dev environment
cd infra-terraform/terraform/envs/dev/

# Verify AWS credentials
aws sts get-caller-identity
```

---

## 🏗️ Infrastructure Deployment

### Phase 1: PostgreSQL RDS Database (KEY-31)

**Purpose**: Provision a dedicated PostgreSQL database for Keycloak to store realm configurations, users, and session data.

**Status**: ✅ **COMPLETE**

**Actions Taken**:
- A reusable Terraform module for RDS was created.
- The module was integrated into the `dev` environment.
- A `db.t4g.micro` PostgreSQL instance was deployed successfully.

**Verification**:
```bash
# Check RDS instance status in AWS Console or via CLI
aws rds describe-db-instances --db-instance-identifier kainam-dev-keycloak-db --query "DBInstances[].DBInstanceStatus"

# Get RDS endpoint from Terraform outputs
terraform output rds_instance_endpoint
```

**Database Details**:
- **Identifier**: `kainam-dev-keycloak-db`
- **Endpoint**: `kainam-dev-keycloak-db.<generated-after-creation>.us-east-2.rds.amazonaws.com:5432`
- **Username**: `keycloak_admin` (managed in Secrets Manager)
- **Database Name**: `kainam_keycloak_rds_pg_dev`

---

### Phase 2: Keycloak Docker Image & ECR Repository (KEY-26-EC2)

**Purpose**: Build and deploy the Keycloak authentication service as a containerized application.

**Status**: ✅ **COMPLETE** - ECR repository and CI/CD pipeline deployed and operational

**Components**:
- ✅ Multi-stage Dockerfile for optimized Keycloak image
- ✅ ECR repository for container image storage (`keycloak-ecr-dev`)
- ✅ CI/CD pipeline for automated builds (`keycloak-cb-pipeline-dev`)

#### 🐳 Docker Configuration

**Dockerfile Location**: `authentication/Dockerfile`

**Build Instructions**:
```bash
# Navigate to authentication directory
cd authentication/

# Build the Docker image
docker build -t keycloak-ecr-dev:latest .

# Tag for ECR
docker tag keycloak-ecr-dev:latest 592172380963.dkr.ecr.us-east-2.amazonaws.com/keycloak-ecr-dev:latest
```

**Local Testing**:
```bash
# Run locally with environment variables
docker run -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  -e KC_DB_URL_HOST=kainam-dev-keycloak-db.<rds-endpoint>.us-east-2.rds.amazonaws.com \
  -e KC_DB_URL_DATABASE=kainam_keycloak_rds_pg_dev \
  -e KC_DB_USERNAME=keycloak_admin \
  -e KC_DB_PASSWORD=<password-from-secrets-manager> \
  -e KC_PROXY_HEADERS=xforwarded \
  -e KC_HTTP_ENABLED=true \
  -e KC_HOSTNAME_STRICT=false \
  keycloak-ecr-dev:latest
```

**Environment Variables Reference**:

*Required Variables*:
- `KEYCLOAK_ADMIN` - Admin username
- `KEYCLOAK_ADMIN_PASSWORD` - Admin password  
- `KC_DB_URL_HOST` - PostgreSQL RDS hostname
- `KC_DB_URL_DATABASE` - Database name
- `KC_DB_USERNAME` - Database username
- `KC_DB_PASSWORD` - Database password

*ALB Integration Variables*:
- `KC_PROXY_HEADERS=xforwarded` - Accept X-Forwarded-* headers from ALB
- `KC_HTTP_ENABLED=true` - Enable HTTP for edge TLS termination
- `KC_HOSTNAME_STRICT=false` - Allow dynamic hostname resolution

*Optional Variables*:
- `KC_HOSTNAME` - Fixed hostname (if not using dynamic)
- `KC_LOG_LEVEL` - Logging level (INFO, DEBUG, etc.)
- `KC_DB_POOL_INITIAL_SIZE` - Database connection pool initial size
- `KC_DB_POOL_MAX_SIZE` - Database connection pool max size

#### 🏗️ Multi-Stage Build Details

**Stage 1 - Builder**:
- Base: `quay.io/keycloak/keycloak:26.3.2`
- Configures PostgreSQL driver
- Enables health and metrics endpoints
- Enables production features (token-exchange, admin-fine-grained-authz)
- Runs `kc.sh build` for optimization

**Stage 2 - Runtime**:
- Copies optimized build from Stage 1
- Runs as non-root `keycloak` user
- Includes health check endpoint
- Uses `start --optimized` command for production performance

#### 📦 ECR Repository Details

**Repository Information:**
- **Repository Name**: `keycloak-ecr-dev`
- **Repository URL**: `592172380963.dkr.ecr.us-east-2.amazonaws.com/keycloak-ecr-dev`
- **Registry ID**: `592172380963`
- **Region**: `us-east-2`

**ECR Login Commands:**
```bash
# Login to ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 592172380963.dkr.ecr.us-east-2.amazonaws.com

# Push Docker image to ECR
docker push 592172380963.dkr.ecr.us-east-2.amazonaws.com/keycloak-ecr-dev:latest
```

**Repository Configuration:**
- **Image Tag Mutability**: MUTABLE (allows overwriting tags during development)
- **Image Scanning**: Enabled on push for security vulnerability detection
- **Encryption**: AES256 encryption at rest
- **Lifecycle Policy**: Keep last 10 tagged images (v* prefix), delete untagged images after 1 day

---

### Phase 3: Deploy Keycloak Server in EC2

**Purpose**: Deploy and configure the Keycloak authentication service on EC2 instance.

**Status**: ✅ **COMPLETE** - Infrastructure deployed and application operational

#### SSH Access to Keycloak EC2 Instance

**Status**: ✅ **COMPLETE** - SSH access configured with AWS Session Manager

**Setup Steps**:

1. **Install AWS Session Manager Plugin** and add to PATH:
   ```powershell
   # Download Session Manager Plugin for Windows
   Invoke-WebRequest -Uri "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe" -OutFile "SessionManagerPluginSetup.exe"
   
   # Install the plugin
   .\SessionManagerPluginSetup.exe
   
   # Add to PATH for current session
   $env:PATH += ";C:\Program Files\Amazon\SessionManagerPlugin\bin"
   
   # Verify installation
   aws ssm start-session --help
   ```

2. **Create credentials wrapper script** at `~/.ssh/aws-ssm-wrapper.bat`:
   ```
   Contact alejandro@kainam.ai to obtain the pre-configured wrapper script 
   with the appropriate AWS credentials for the development environment.
   ```

3. **Add SSH config** to `~/.ssh/config`:
   ```ssh
   Host keycloak-dev
       HostName i-<instance-id>
       User ubuntu
       ProxyCommand "C:\\Users\\<username>\\.ssh\\aws-ssm-wrapper.bat" --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p
       IdentityFile "C:\\Users\\<username>\\.ssh\\<pem-file>.pem"
   ```

**Test Connection**:
```bash
# Test SSH connection
ssh keycloak-dev

# Or connect via IDE (VS Code/Cursor)
# Ctrl+Shift+P → "Remote-SSH: Connect to Host" → keycloak-dev
```

4. **Access EC2 Instance**:
```bash
aws ssm start-session --target i-<instance-id>
```

#### Keycloak Application Configuration (Manual)

Use this method if the bootstrap script fails.

**Steps**:

##### Phase 1: Install Docker and AWS CLI

1. SSH into the EC2 instance. Use the steps above to do so. [Keycloak EC2 SSH Access](#ssh-access-to-keycloak-ec2-instance)

2. Update system packages.
```bash
sudo apt-get update -y
```

3. Install basic dependencies - Unzip tool and Docker.
```bash
sudo apt-get install -y curl unzip docker.io jq
```

4. Install AWS CLI.
```bash
cd /tmp && \
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
unzip awscliv2.zip && \
sudo ./aws/install
---

5. Verify AWS CLI is installed.
```bash
aws --version
```

##### Phase 2: Setup Docker

1. Start Docker service.
```bash
sudo systemctl start docker
```

2. Enable Docker service.
```bash
sudo systemctl enable docker
```

3. Add ubuntu user to docker group.
```bash
sudo usermod -aG docker ubuntu
```

4. Verify Docker is running.
```bash
sudo systemctl status docker
```

5. Verify Docker is installed.
```bash
docker --version
```

##### Phase 3: Deploy Keycloak

1. Login to ECR.
```bash
aws ecr get-login-password --region us-east-2 | sudo docker login --username AWS --password-stdin 592172380963.dkr.ecr.us-east-2.amazonaws.com
```

2. Test secrets fetching.
```bash
aws secretsmanager get-secret-value --region us-east-2 --secret-id "keystone/dev/database" --query SecretString --output text
aws secretsmanager get-secret-value --region us-east-2 --secret-id "keystone/dev/keycloak_admin" --query SecretString --output text
```

3. Pull Keycloak image from ECR.
```bash
sudo docker pull 592172380963.dkr.ecr.us-east-2.amazonaws.com/keycloak-ecr-dev:latest
```

4. Clean up existing Keycloak container (if exists).
```bash
sudo docker stop keycloak-auth-dev || true && sudo docker rm keycloak-auth-dev || true
```
Note: If the container doesn't exists, the command will fail with "No such container: keycloak-auth-dev".

5. Deploy Keycloak container.

Multi line command:
```bash
sudo docker run -d \
    --name keycloak-auth-dev \
    --restart unless-stopped \
    -p 8080:8080 \
    -e KC_HOSTNAME_URL="https://auth-dev.kainam.app" \
    -e KC_DB_URL="jdbc:postgresql://kainam-dev-keycloak-db.cdik4w8gupyh.us-east-2.rds.amazonaws.com:5432/kainam_keycloak_rds_pg_dev" \
    -e KC_DB_USERNAME="keycloak_admin" \
    -e KC_DB_PASSWORD="800rsfpxlP5VP4tZ" \
    -e KC_BOOTSTRAP_ADMIN_USERNAME="admin-cli" \
    -e KC_BOOTSTRAP_ADMIN_PASSWORD="QXRKjtKdIGlRchoE" \
    -e KC_PROXY=edge \
    -e KC_PROXY_HEADERS=xforwarded \
    -e KC_HOSTNAME_STRICT=false \
    -e KC_HOSTNAME_STRICT_HTTPS=false \
    -e KC_HTTP_ENABLED=true \
    -e KC_HEALTH_ENABLED=true \
    -e KC_METRICS_ENABLED=true \
    --health-cmd="wget --no-verbose --tries=1 --spider http://localhost:8080/health/ready || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --health-start-period=60s \
    592172380963.dkr.ecr.us-east-2.amazonaws.com/keycloak-ecr-dev:latest
```

Single line command:
```bash
sudo docker run -d --name keycloak-auth-dev --restart unless-stopped -p 8080:8080 -e KC_HOSTNAME_URL="https://auth-dev.kainam.app" -e KC_DB_URL="jdbc:postgresql://kainam-dev-keycloak-db.cdik4w8gupyh.us-east-2.rds.amazonaws.com:5432/kainam_keycloak_rds_pg_dev" -e KC_DB_USERNAME="keycloak_admin" -e KC_DB_PASSWORD="800rsfpxlP5VP4tZ" -e KC_BOOTSTRAP_ADMIN_USERNAME="admin-cli" -e KC_BOOTSTRAP_ADMIN_PASSWORD="QXRKjtKdIGlRchoE" -e KC_PROXY=edge -e KC_PROXY_HEADERS=xforwarded -e KC_HOSTNAME_STRICT=false -e KC_HOSTNAME_STRICT_HTTPS=false -e KC_HTTP_ENABLED=true -e KC_HEALTH_ENABLED=true -e KC_METRICS_ENABLED=true --health-cmd="wget --no-verbose --tries=1 --spider http://localhost:8080/health/ready || exit 1" --health-interval=30s --health-timeout=10s --health-retries=3 --health-start-period=60s 592172380963.dkr.ecr.us-east-2.amazonaws.com/keycloak-ecr-dev:latest
```

##### Phase 4: Verify Keycloak is running

1. Check if the container is running.
```bash
sudo docker ps
```

2. Check the container logs.
```bash
sudo docker logs keycloak-auth-dev
```

3. Check the container health.
```bash
curl -f http://localhost:8080/health/ready
```

4. Check if the Keycloak admin console is accessible by accessing the admin console.
```bash
curl -f http://localhost:8080/realms/master
```

---

### Phase 4: Configure Keycloak Realm and Clients (KEY-28)

**Purpose**: Configure the kainam-dev realm with OIDC clients for SENNA integration.

**Status**: ✅ **COMPLETE** - Realm and clients configured with secrets stored in AWS Secrets Manager

#### Method 1: Automated Configuration (Recommended)

**Prerequisites:**
- SSH access to Keycloak EC2 instance (see Phase 3)
- Java 17+ installed (script will check and offer installation)

**Steps:**

1. **Navigate to the authentication directory:**
```bash
cd authentication/
```

2. **Make the configuration script executable:**
```bash
chmod +x scripts/configure_keycloak_clients.sh
```

3. **Run the automated configuration script:**
```bash
./scripts/configure_keycloak_clients.sh --env dev
```

4. **Follow the interactive prompts:**
   - **Keycloak Admin Username**: Enter `admin-cli` (or press Enter for default)
   - **Keycloak Admin Password**: Enter the admin password (hidden input)
   - The script will automatically:
     - Check for Java 17+ and offer installation if needed
     - Download and install `kcadm.sh` if not found
     - Create the `kainam-dev` realm
     - Configure both SENNA clients with proper settings
     - Display the generated client secret

5. **Record the client secret from the output:**
```bash
# Example output:
[SUCCESS] Client 'senna-backend' created successfully
[INFO] Generated Client Secret: EkWnY7qgoYZbRWsW01KvbumkFSxgWm49
[INFO] Please store this secret securely in AWS Secrets Manager
```

#### Method 2: Manual Configuration via Admin Console

**If the automated script fails, use this manual approach:**

1. **Access the Keycloak Admin Console:**
```bash
# Open in browser
https://auth-dev.kainam.app/admin
```

2. **Login with admin credentials:**
   - Username: `admin-cli`
   - Password: (from AWS Secrets Manager: `keystone/dev/keycloak_admin`)

3. **Create the kainam-dev realm:**
   - Click "Add realm"
   - Realm name: `kainam-dev`
   - Click "Create"

4. **Create SENNA Frontend Client:**
   - Navigate to "Clients" → "Create"
   - Client ID: `senna-frontend`
   - Client Protocol: `openid-connect`
   - Root URL: `https://senna-dev.kainam.app`
   - Click "Save"
   - **Settings Tab:**
     - Access Type: `public`
     - Standard Flow Enabled: `ON`
     - Direct Access Grants Enabled: `OFF`
     - Valid Redirect URIs: `https://senna-dev.kainam.app/*`
     - Web Origins: `+`
   - Click "Save"

5. **Create SENNA Backend Client:**
   - Navigate to "Clients" → "Create"
   - Client ID: `senna-backend`
   - Client Protocol: `openid-connect`
   - Click "Save"
   - **Settings Tab:**
     - Access Type: `confidential`
     - Standard Flow Enabled: `OFF`
     - Direct Access Grants Enabled: `ON`
     - Service Accounts Enabled: `ON`
   - Click "Save"
   - **Credentials Tab:**
     - Copy the generated "Secret" value

#### Store Client Secret in AWS Secrets Manager

**Using Terraform (Recommended):**

1. **Add the client secret to secrets.tfvars:**
```bash
# Edit infra-terraform/terraform/secrets.tfvars
senna_backend_client_secret = "EkWnY7qgoYZbRWsW01KvbumkFSxgWm49"
```

2. **Deploy the secret via Terraform:**
```bash
cd infra-terraform/terraform/envs/dev/
terraform plan -var-file="../../secrets.tfvars"
terraform apply -var-file="../../secrets.tfvars"
```

**Using AWS CLI (Alternative):**
```bash
aws secretsmanager create-secret \
    --name "keystone/dev/backend_client_secret" \
    --description "SENNA backend client secret from Keycloak" \
    --secret-string '{"client_secret":"EkWnY7qgoYZbRWsW01KvbumkFSxgWm49"}' \
    --region us-east-2
```

#### Verification Steps

1. **Verify realm creation:**
```bash
curl -f https://auth-dev.kainam.app/realms/kainam-dev/.well-known/openid_configuration
```

2. **Verify client configuration in admin console:**
   - Navigate to: `https://auth-dev.kainam.app/admin`
   - Select "kainam-dev" realm
   - Go to "Clients"
   - Verify both `senna-frontend` and `senna-backend` clients exist

3. **Test OIDC endpoints:**
```bash
# Authorization endpoint (should return HTML login page)
curl -s https://auth-dev.kainam.app/realms/kainam-dev/protocol/openid-connect/auth

# Token endpoint (should return method not allowed for GET)
curl -s https://auth-dev.kainam.app/realms/kainam-dev/protocol/openid-connect/token
```

4. **Verify secret in AWS Secrets Manager:**
```bash
aws secretsmanager describe-secret \
    --secret-id "keystone/dev/backend_client_secret" \
    --region us-east-2
```

#### Expected Configuration Results

**Realm Configuration:**
- **Realm Name**: `kainam-dev`
- **Access URL**: `https://auth-dev.kainam.app/realms/kainam-dev`
- **Admin Console**: `https://auth-dev.kainam.app/admin`

**SENNA Frontend Client:**
- **Client ID**: `senna-frontend`
- **Access Type**: Public
- **Valid Redirect URIs**: `https://senna-dev.kainam.app/*`
- **Web Origins**: `+`

**SENNA Backend Client:**
- **Client ID**: `senna-backend`
- **Access Type**: Confidential
- **Client Secret**: Stored in `keystone/dev/backend_client_secret`
- **Service Accounts**: Enabled

**Next Steps:**
1. Integrate SENNA Backend with JWT validation middleware
2. Integrate SENNA Frontend with OIDC authentication flow
3. Test end-to-end authentication flow

---

## 🚨 Troubleshooting

### RDS Connection Issues
- Verify the EC2 instance's security group allows outbound traffic to the RDS security group on port 5432.
- Check the Keycloak container logs for database connection errors.

### ECR Authentication Issues
- Ensure AWS CLI is configured with proper credentials
- Verify IAM permissions for ECR access
- Check ECR repository exists in the correct region (us-east-2)

### CI/CD Pipeline Issues
- **Pipeline Not Triggering**: Verify changes are made to `authentication/**` files and pushed to `dev` branch
- **Build Failures**: Check CodeBuild logs in CloudWatch for detailed error messages
- **ECR Push Failures**: Verify CodeBuild IAM role has proper ECR permissions
- **Path Filtering Issues**: Ensure git history is available for path comparison (not shallow clones)

### SSH Access Issues
- **"Unable to locate credentials"**: Update AWS credentials in `aws-ssm-wrapper.bat`
- **"TargetNotConnected"**: Ensure EC2 instance is running and SSM Agent is active
- **"SessionManagerPlugin not found"**: Install Session Manager Plugin and add to PATH
- **SSH connection fails**: Test `aws ssm start-session --target i-0b53d307ca0b3c67e` first

### Keycloak Realm Configuration Issues
- **"Realm not found"**: Verify realm creation via admin console or OIDC discovery endpoint
- **"Client authentication failed"**: Check client secret matches value in AWS Secrets Manager
- **"Invalid redirect URI"**: Ensure redirect URIs match exactly (including trailing /* for SPAs)
- **"kcadm.sh not found"**: Script will auto-install Keycloak CLI if not in PATH
- **"Java version incompatible"**: Keycloak 26.3.2 requires Java 17+, script checks and offers installation
- **"Authentication failed"**: Verify Keycloak admin credentials and service accessibility

### AWS Secrets Manager Issues
- **"AccessDenied"**: Verify EC2 instance has `keystone-ec2-role` attached
- **"SecretNotFound"**: Confirm secret exists: `aws secretsmanager describe-secret --secret-id "keystone/dev/backend_client_secret"`
- **"InvalidJSON"**: Secret value should be valid JSON: `{"client_secret": "..."}`

---

*This runbook is a living document and will be updated as the deployment progresses.*