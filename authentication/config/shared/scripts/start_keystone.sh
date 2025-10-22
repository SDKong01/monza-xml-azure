#!/bin/bash

# Keystone RBAC - Startup Script with Secrets Integration
# Purpose: Fetch AWS secrets and start all Keystone services
# Usage: ./scripts/start_keystone.sh
# Author: Backend Engineer
# Last Updated: 2025-01-27

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
COMPOSE_FILE="${PROJECT_DIR}/docker-compose.yml"
ENV_FILE="${PROJECT_DIR}/.env"
LOG_PREFIX="[KEYSTONE-STARTUP]"

# Logging function
log() {
    echo "${LOG_PREFIX} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Main startup process
main() {
    log "Starting Keystone RBAC application with AWS Secrets Manager integration..."
    
    # Change to project directory
    cd "${PROJECT_DIR}" || error_exit "Failed to change to project directory: ${PROJECT_DIR}"
    
    # Source the secrets fetching script to load environment variables
    log "Fetching credentials from AWS Secrets Manager..."
    source "${SCRIPT_DIR}/fetch_secrets.sh" || error_exit "Failed to fetch secrets from AWS"
    
    # Load additional environment variables from .env (OAuth2 config, ports, etc.)
    if [[ -f "${ENV_FILE}" ]]; then
        log "Loading additional configuration from ${ENV_FILE}..."
        set -a  # Automatically export all variables
        source "${ENV_FILE}" || error_exit "Failed to load environment file: ${ENV_FILE}"
        set +a  # Disable automatic export
        
        # Verify OAuth2 variables are loaded
        log "Verifying OAuth2 configuration..."
        if [[ -z "${OAUTH2_PROXY_OIDC_ISSUER_URL:-}" ]]; then
            error_exit "OAUTH2_PROXY_OIDC_ISSUER_URL not found in ${ENV_FILE}"
        fi
        log "OAuth2 configuration verified: ${OAUTH2_PROXY_OIDC_ISSUER_URL}"
    else
        log "WARNING: Environment file not found: ${ENV_FILE}"
    fi
    
    # Verify required environment variables are set
    log "Verifying environment variables..."
    required_vars=(
        "POSTGRES_USER" "POSTGRES_PASSWORD" "POSTGRES_DB"
        "KEYCLOAK_ADMIN" "KEYCLOAK_ADMIN_PASSWORD"
        "OAUTH2_PROXY_CLIENT_SECRET" "OAUTH2_PROXY_COOKIE_SECRET"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            error_exit "Required environment variable ${var} is not set"
        fi
    done
    
    log "All required environment variables verified"
    
    # Start services with docker-compose
    log "Starting Keystone services with docker-compose..."
    docker-compose -f "${COMPOSE_FILE}" up -d || error_exit "Failed to start services with docker-compose"
    
    log "Keystone RBAC services started successfully!"
    log "Services status:"
    docker-compose -f "${COMPOSE_FILE}" ps
    
    # Get EC2 public IP with IMDSv2 token (required for newer EC2 instances)
    TOKEN=$(curl -s --max-time 5 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" 2>/dev/null || echo "")
    if [[ -n "$TOKEN" ]]; then
        EC2_PUBLIC_IP=$(curl -s --max-time 5 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "18.191.64.107")
    else
        EC2_PUBLIC_IP="18.191.64.107"
    fi
    
    log "NGINX Gateway will be available at: http://${EC2_PUBLIC_IP}:81"
    log "Keycloak Admin Console: http://${EC2_PUBLIC_IP}:81/admin"
    log "Application Frontend: http://${EC2_PUBLIC_IP}:81/"
    log "API Endpoint: http://${EC2_PUBLIC_IP}:81/api/v1/me"
    log "OAuth2 Authentication: http://${EC2_PUBLIC_IP}:81/oauth2/start"
    log "Startup complete!"
}

# Handle script interruption
cleanup() {
    log "Received interrupt signal. Cleaning up..."
    docker-compose -f "${COMPOSE_FILE}" down 2>/dev/null || true
    exit 130
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Execute main function
main "$@"
