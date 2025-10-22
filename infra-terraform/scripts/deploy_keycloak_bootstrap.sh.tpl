#!/bin/bash

# Keycloak EC2 Bootstrap Script
# Purpose: Minimal bootstrap to download and execute full deployment script
# Author: A. Aguirre | alejandro@kainam.ai
# Last Updated: 2025-09-06

set -euo pipefail

# Environment Configuration (injected by Terraform)
ENVIRONMENT="${environment}"
PROJECT_NAME="${project_name}"
AWS_REGION="${aws_region}"
AWS_ACCOUNT_ID="${aws_account_id}"

# ECR Configuration
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
ECR_REPOSITORY="${ecr_repository}"
IMAGE_TAG="${image_tag}"

# Database Configuration
RDS_ENDPOINT="${rds_endpoint}"
DB_NAME="${db_name}"
DB_PORT="${db_port}"

# Keycloak Configuration
KC_HOSTNAME="${kc_hostname}"
KC_HTTP_PORT="${kc_http_port}"
CONTAINER_NAME="${container_name}"

# Secrets Manager Configuration
DATABASE_SECRET_NAME="${database_secret_name}"
KEYCLOAK_SECRET_NAME="${keycloak_secret_name}"

# Logging
LOG_FILE="/var/log/keycloak-deployment.log"

log() {
    echo "[KEYCLOAK-BOOTSTRAP] $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Update system and install dependencies
log "Starting Keycloak deployment bootstrap"
sudo apt-get update -y || error_exit "Failed to update system"
sudo apt-get install -y curl unzip docker.io jq || error_exit "Failed to install dependencies"

# Install AWS CLI v2 (official method - awscli package not available in Ubuntu 24.04)
log "Installing AWS CLI v2"
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || error_exit "Failed to download AWS CLI"
unzip awscliv2.zip || error_exit "Failed to unzip AWS CLI"
sudo ./aws/install || error_exit "Failed to install AWS CLI"
aws --version || error_exit "AWS CLI installation verification failed"

# Start Docker
sudo systemctl start docker || error_exit "Failed to start Docker"
sudo systemctl enable docker || error_exit "Failed to enable Docker"
sudo usermod -aG docker ubuntu || error_exit "Failed to add ubuntu to docker group"

# ECR Login
log "Authenticating with ECR"
aws ecr get-login-password --region "$AWS_REGION" | sudo docker login --username AWS --password-stdin "$ECR_REGISTRY" || error_exit "ECR login failed"

# Fetch secrets
log "Fetching database credentials"
DB_SECRET=$(aws secretsmanager get-secret-value --region "$AWS_REGION" --secret-id "$DATABASE_SECRET_NAME" --query SecretString --output text) || error_exit "Failed to fetch database secret"
DB_USERNAME=$(echo "$DB_SECRET" | jq -r '.username') || error_exit "Failed to parse database username"
DB_PASSWORD=$(echo "$DB_SECRET" | jq -r '.password') || error_exit "Failed to parse database password"

log "Fetching Keycloak admin credentials"
KC_SECRET=$(aws secretsmanager get-secret-value --region "$AWS_REGION" --secret-id "$KEYCLOAK_SECRET_NAME" --query SecretString --output text) || error_exit "Failed to fetch Keycloak secret"
KEYCLOAK_ADMIN=$(echo "$KC_SECRET" | jq -r '.username') || error_exit "Failed to parse Keycloak username"
KEYCLOAK_ADMIN_PASSWORD=$(echo "$KC_SECRET" | jq -r '.password') || error_exit "Failed to parse Keycloak password"

# Pull and deploy Keycloak
log "Pulling Keycloak image"
FULL_IMAGE_NAME="$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG"
sudo docker pull "$FULL_IMAGE_NAME" || error_exit "Failed to pull Keycloak image"

# Stop existing container if running
if sudo docker ps -a --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    log "Stopping existing container"
    sudo docker stop "$CONTAINER_NAME" || true
    sudo docker rm "$CONTAINER_NAME" || true
fi

# Deploy Keycloak container
log "Deploying Keycloak container"
DB_URL="jdbc:postgresql://$RDS_ENDPOINT:$DB_PORT/$DB_NAME"

sudo docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    -p "$KC_HTTP_PORT:8080" \
    -e KC_HOSTNAME="$KC_HOSTNAME" \
    -e KC_DB_URL="$DB_URL" \
    -e KC_DB_USERNAME="$DB_USERNAME" \
    -e KC_DB_PASSWORD="$DB_PASSWORD" \
    -e KEYCLOAK_ADMIN="$KEYCLOAK_ADMIN" \
    -e KEYCLOAK_ADMIN_PASSWORD="$KEYCLOAK_ADMIN_PASSWORD" \
    -e KC_PROXY=edge \
    -e KC_HOSTNAME_STRICT=false \
    -e KC_HOSTNAME_STRICT_HTTPS=false \
    -e KC_HTTP_ENABLED=true \
    -e KC_HEALTH_ENABLED=true \
    -e KC_METRICS_ENABLED=true \
    --health-cmd="curl -f http://localhost:8080/health/ready || exit 1" \
    --health-interval=30s \
    --health-timeout=10s \
    --health-retries=3 \
    --health-start-period=60s \
    "$FULL_IMAGE_NAME" || error_exit "Failed to deploy Keycloak container"

# Wait for health check
log "Waiting for Keycloak to be ready"
for i in {1..30}; do
    if sudo docker exec "$CONTAINER_NAME" curl -f http://localhost:8080/realms/master &>/dev/null; then
        log "SUCCESS: Keycloak is ready and healthy (attempt $i/30)"
        break
    fi
    log "Keycloak not ready yet (attempt $i/30), waiting 10 seconds..."
    sleep 10
    if [ $i -eq 30 ]; then
        error_exit "Keycloak failed to become ready after 30 attempts"
    fi
done

log "SUCCESS: Keycloak deployment completed successfully!"
log "Container: $CONTAINER_NAME is running on port $KC_HTTP_PORT"
log "Health endpoint: http://localhost:$KC_HTTP_PORT/health/ready"
log "Admin console: https://$KC_HOSTNAME/admin"
log "Deployment logs saved to: $LOG_FILE"
