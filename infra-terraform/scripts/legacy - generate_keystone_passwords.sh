#!/bin/bash

# Keystone Secrets Password Generator
# Generates secure 16-character alphanumeric passwords for Keystone secrets
# Usage: ./generate_keystone_passwords.sh

set -e

# Function to generate a 16-character alphanumeric password
generate_password() {
    # Generate 16-character password using only letters and numbers
    # Using /dev/urandom for cryptographically secure randomness
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16
}

# Function to create or update terraform.tfvars file
update_tfvars() {
    local tfvars_file="$1"
    local rds_password="$2"
    local keycloak_password="$3"
    
    echo "# Keystone Secrets Configuration - Generated $(date -u '+%Y-%m-%d %H:%M:%S UTC')" > "$tfvars_file"
    echo "# WARNING: This file contains sensitive credentials - never commit to version control" >> "$tfvars_file"
    echo "" >> "$tfvars_file"
    echo "# Database credentials for keystone/dev/database secret" >> "$tfvars_file"
    echo "rds_username = \"admin\"" >> "$tfvars_file"
    echo "rds_password = \"$rds_password\"" >> "$tfvars_file"
    echo "" >> "$tfvars_file"
    echo "# Keycloak admin credentials for keystone/dev/keycloak_admin secret" >> "$tfvars_file"
    echo "keycloak_username = \"admin-cli\"" >> "$tfvars_file"
    echo "keycloak_password = \"$keycloak_password\"" >> "$tfvars_file"
}

# Main execution
main() {
    echo "🔐 Keystone Secrets Password Generator"
    echo "======================================="
    
    # Generate secure passwords
    echo "🎲 Generating secure passwords..."
    RDS_PASSWORD=$(generate_password)
    KEYCLOAK_PASSWORD=$(generate_password)
    
    # Validate passwords
    if [[ ${#RDS_PASSWORD} -ne 16 ]] || [[ ${#KEYCLOAK_PASSWORD} -ne 16 ]]; then
        echo "❌ Error: Generated passwords are not 16 characters long"
        exit 1
    fi
    
    if [[ ! "$RDS_PASSWORD" =~ ^[A-Za-z0-9]+$ ]] || [[ ! "$KEYCLOAK_PASSWORD" =~ ^[A-Za-z0-9]+$ ]]; then
        echo "❌ Error: Generated passwords contain invalid characters"
        exit 1
    fi
    
    echo "✅ Generated 16-character alphanumeric passwords"
    
    # Determine output directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/terraform"
    TFVARS_FILE="$TERRAFORM_DIR/secrets.tfvars"
    
    # Create terraform.tfvars file
    echo "📝 Creating secrets.tfvars file..."
    update_tfvars "$TFVARS_FILE" "$RDS_PASSWORD" "$KEYCLOAK_PASSWORD"
    
    echo "✅ Secrets configuration saved to: $TFVARS_FILE"
    echo ""
    echo "🔒 Security Notes:"
    echo "   • Never commit secrets.tfvars to version control"
    echo "   • Add secrets.tfvars to .gitignore if not already present"
    echo "   • Store passwords securely and rotate regularly"
    echo ""
    echo "📋 Generated Credentials:"
    echo "   • RDS Database: admin / [16-char password]"
    echo "   • Keycloak Admin: admin-cli / [16-char password]"
    echo ""
    echo "🚀 Next Steps:"
    echo "   1. Review the generated secrets.tfvars file"
    echo "   2. Run 'terraform plan -var-file=secrets.tfvars' to validate"
    echo "   3. Run 'terraform apply -var-file=secrets.tfvars' to deploy secrets"
}

# Execute main function
main "$@"
