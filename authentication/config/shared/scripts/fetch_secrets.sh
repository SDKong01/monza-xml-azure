#!/bin/bash

# Keystone RBAC - AWS Secrets Manager Integration Script
# Purpose: Fetch database and Keycloak admin credentials from AWS Secrets Manager
# Usage: source ./scripts/fetch_secrets.sh
# Author: Backend Engineer
# Last Updated: 2025-01-27

set -euo pipefail  # Exit on any error, undefined variable, or pipe failure

# Configuration
AWS_REGION="us-east-2"
DATABASE_SECRET_NAME="keystone/dev/database"
KEYCLOAK_SECRET_NAME="keystone/dev/keycloak_admin"
LOG_PREFIX="[SECRETS]"

# Logging function
log() {
    echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        log "AWS CLI not found. Installing AWS CLI v2..."
        
        # Install AWS CLI v2 for Ubuntu
        cd /tmp
        curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || error_exit "Failed to download AWS CLI"
        
        if ! command -v unzip &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y unzip || error_exit "Failed to install unzip"
        fi
        
        unzip -q awscliv2.zip || error_exit "Failed to extract AWS CLI"
        sudo ./aws/install || error_exit "Failed to install AWS CLI"
        rm -rf awscliv2.zip aws
        
        log "AWS CLI v2 installed successfully"
    else
        log "AWS CLI found: $(aws --version)"
    fi
}

# Check if jq is installed
check_jq() {
    if ! command -v jq &> /dev/null; then
        log "jq not found. Installing jq..."
        sudo apt-get update && sudo apt-get install -y jq || error_exit "Failed to install jq"
        log "jq installed successfully"
    else
        log "jq found: $(jq --version)"
    fi
}

# Fetch and parse database credentials
fetch_database_credentials() {
    log "Fetching database credentials from ${DATABASE_SECRET_NAME}..."
    
    local secret_value
    secret_value=$(aws secretsmanager get-secret-value \
        --region "${AWS_REGION}" \
        --secret-id "${DATABASE_SECRET_NAME}" \
        --query SecretString \
        --output text 2>/dev/null) || error_exit "Failed to fetch database secret"
    
    # Parse JSON and extract credentials
    POSTGRES_USER=$(echo "${secret_value}" | jq -r '.username') || error_exit "Failed to parse database username"
    POSTGRES_PASSWORD=$(echo "${secret_value}" | jq -r '.password') || error_exit "Failed to parse database password"
    
    # Validate credentials are not null
    [[ "${POSTGRES_USER}" != "null" && "${POSTGRES_USER}" != "" ]] || error_exit "Database username is null or empty"
    [[ "${POSTGRES_PASSWORD}" != "null" && "${POSTGRES_PASSWORD}" != "" ]] || error_exit "Database password is null or empty"
    
    # Export environment variables
    export POSTGRES_USER
    export POSTGRES_PASSWORD
    export POSTGRES_DB="keycloak"  # Database name remains constant
    
    log "Database credentials successfully fetched and exported"
}

# Fetch and parse Keycloak admin credentials  
fetch_keycloak_credentials() {
    log "Fetching Keycloak admin credentials from ${KEYCLOAK_SECRET_NAME}..."
    
    local secret_value
    secret_value=$(aws secretsmanager get-secret-value \
        --region "${AWS_REGION}" \
        --secret-id "${KEYCLOAK_SECRET_NAME}" \
        --query SecretString \
        --output text 2>/dev/null) || error_exit "Failed to fetch Keycloak secret"
    
    # Parse JSON and extract credentials
    KEYCLOAK_ADMIN=$(echo "${secret_value}" | jq -r '.username') || error_exit "Failed to parse Keycloak username"
    KEYCLOAK_ADMIN_PASSWORD=$(echo "${secret_value}" | jq -r '.password') || error_exit "Failed to parse Keycloak password"
    
    # Validate credentials are not null
    [[ "${KEYCLOAK_ADMIN}" != "null" && "${KEYCLOAK_ADMIN}" != "" ]] || error_exit "Keycloak username is null or empty"
    [[ "${KEYCLOAK_ADMIN_PASSWORD}" != "null" && "${KEYCLOAK_ADMIN_PASSWORD}" != "" ]] || error_exit "Keycloak password is null or empty"
    
    # Export environment variables
    export KEYCLOAK_ADMIN
    export KEYCLOAK_ADMIN_PASSWORD
    
    log "Keycloak admin credentials successfully fetched and exported"
}

# Verify AWS credentials and region
verify_aws_setup() {
    log "Verifying AWS setup..."
    
    # Check AWS credentials
    aws sts get-caller-identity --region "${AWS_REGION}" &>/dev/null || error_exit "AWS credentials not configured or invalid"
    
    # Check IAM permissions for Secrets Manager
    aws secretsmanager describe-secret --secret-id "${DATABASE_SECRET_NAME}" --region "${AWS_REGION}" &>/dev/null || error_exit "No permission to access database secret"
    aws secretsmanager describe-secret --secret-id "${KEYCLOAK_SECRET_NAME}" --region "${AWS_REGION}" &>/dev/null || error_exit "No permission to access Keycloak secret"
    
    log "AWS setup verified successfully"
}

# Main execution
main() {
    log "Starting AWS Secrets Manager credential fetch process..."
    
    # Install dependencies
    check_aws_cli
    check_jq
    
    # Verify AWS setup
    verify_aws_setup
    
    # Fetch credentials
    fetch_database_credentials
    fetch_keycloak_credentials
    
    log "All credentials successfully fetched and exported. Ready for docker-compose startup."
    log "Environment variables set: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB, KEYCLOAK_ADMIN, KEYCLOAK_ADMIN_PASSWORD"
}

# Execute main function
main "$@"
