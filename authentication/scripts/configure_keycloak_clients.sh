#!/bin/bash

# =============================================================================
# Keycloak Client Configuration Script
# =============================================================================
# This script configures the Keycloak realm with SENNA frontend and backend clients
# using the Keycloak Admin CLI and the realm export JSON file with dynamic environment
# configuration.
#
# Prerequisites:
# - Keycloak server must be running and accessible
# - Admin credentials must be available
# - keycloak-realm-app-export.json must exist in the authentication/ directory
#
# Usage: 
#   ./configure_keycloak_clients.sh --env dev
#   ./configure_keycloak_clients.sh --env uat
#   ./configure_keycloak_clients.sh --env prod
# =============================================================================

set -euo pipefail

# Default Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTH_DIR="$(dirname "$SCRIPT_DIR")"
EXPORT_FILE="$AUTH_DIR/config/templates/keycloak-realm-app-export.json"
ENVIRONMENT=""
KEYCLOAK_SERVER_URL=""
KEYCLOAK_REALM=""
FRONTEND_REDIRECT_URI=""
KEYCLOAK_ADMIN_USER=""
KEYCLOAK_ADMIN_PASSWORD=""
KCADM_PATH=""
KEYCLOAK_INSTALL_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Show usage information
show_usage() {
    echo "Usage: $0 --env <environment>"
    echo
    echo "Arguments:"
    echo "  --env <environment>    Target environment (dev, uat, prod)"
    echo
    echo "Environment Options:"
    echo "  dev     - Development environment"
    echo "            Realm: kainam-dev"
    echo "            Server: https://auth-dev.kainam.app"
    echo "            Frontend: https://senna-dev.kainam.app/*"
    echo
    echo "  uat     - UAT environment"
    echo "            Realm: kainam-uat"
    echo "            Server: https://auth-uat.kainam.app"
    echo "            Frontend: https://senna-uat.kainam.app/*"
    echo
    echo "  prod    - Production environment"
    echo "            Realm: kainam-prod"
    echo "            Server: https://auth.kainam.app"
    echo "            Frontend: https://senna.kainam.app/*"
    echo
    echo "Environment Variables:"
    echo "  KCADM_PATH                 Path to kcadm.sh (auto-detected or installed)"
    echo "  KEYCLOAK_INSTALL_DIR       Directory to install Keycloak (default: /opt/keycloak)"
    echo
    echo "Keycloak Admin CLI:"
    echo "  The script will automatically detect or install kcadm.sh if not found."
    echo
    echo "Interactive Authentication:"
    echo "  The script will prompt for Keycloak admin credentials when running."
    echo
    echo "Examples:"
    echo "  $0 --env dev"
    echo "  $0 --env prod"
}

# Parse command line arguments
parse_arguments() {
    if [[ $# -eq 0 ]]; then
        log_error "No arguments provided"
        show_usage
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --env)
                ENVIRONMENT="$2"
                shift 2
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    # Validate environment
    if [[ -z "$ENVIRONMENT" ]]; then
        log_error "Environment not specified"
        show_usage
        exit 1
    fi

    if [[ ! "$ENVIRONMENT" =~ ^(dev|uat|prod)$ ]]; then
        log_error "Invalid environment: $ENVIRONMENT"
        log_error "Valid environments: dev, uat, prod"
        exit 1
    fi
}

# Set environment-specific configuration
set_environment_config() {
    log_info "Setting configuration for environment: $ENVIRONMENT"
    
    case "$ENVIRONMENT" in
        dev)
            KEYCLOAK_SERVER_URL="https://auth-dev.kainam.app"
            KEYCLOAK_REALM="kainam-dev"
            FRONTEND_REDIRECT_URI="https://senna-dev.kainam.app/*"
            ;;
        uat)
            KEYCLOAK_SERVER_URL="https://auth-uat.kainam.app"
            KEYCLOAK_REALM="kainam-uat"
            FRONTEND_REDIRECT_URI="https://senna-uat.kainam.app/*"
            ;;
        prod)
            KEYCLOAK_SERVER_URL="https://auth.kainam.app"
            KEYCLOAK_REALM="kainam-prod"
            FRONTEND_REDIRECT_URI="https://senna.kainam.app/*"
            ;;
    esac
    
    log_info "Server URL: $KEYCLOAK_SERVER_URL"
    log_info "Realm: $KEYCLOAK_REALM"
    log_info "Frontend Redirect URI: $FRONTEND_REDIRECT_URI"
}

# Prompt for admin credentials
prompt_for_credentials() {
    log_info "Keycloak Admin Authentication Required"
    echo "======================================================================"
    echo "Please provide Keycloak admin credentials for: $KEYCLOAK_SERVER_URL"
    echo "======================================================================"
    echo
    
    # Prompt for username
    read -p "Keycloak Admin Username [admin-cli]: " input_username
    KEYCLOAK_ADMIN_USER="${input_username:-admin-cli}"
    
    # Prompt for password (hidden input)
    echo -n "Keycloak Admin Password: "
    read -s KEYCLOAK_ADMIN_PASSWORD
    echo  # New line after hidden input
    echo
    
    # Validate inputs
    if [[ -z "$KEYCLOAK_ADMIN_USER" ]]; then
        log_error "Username cannot be empty"
        exit 1
    fi
    
    if [[ -z "$KEYCLOAK_ADMIN_PASSWORD" ]]; then
        log_error "Password cannot be empty"
        exit 1
    fi
    
    log_success "Credentials received for user: $KEYCLOAK_ADMIN_USER"
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Linux*)
            echo "linux"
            ;;
        Darwin*)
            echo "macos"
            ;;
        CYGWIN*|MINGW*|MSYS*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if kcadm.sh is available and install if needed
setup_keycloak_cli() {
    log_info "Setting up Keycloak Admin CLI..."
    
    # First, check if kcadm.sh is already in PATH
    if command -v kcadm.sh &> /dev/null; then
        KCADM_PATH="kcadm.sh"
        local kcadm_location=$(which kcadm.sh)
        log_success "Found kcadm.sh in PATH: $kcadm_location"
        return 0
    fi
    
    # Check if KCADM_PATH environment variable is set and valid
    if [[ -n "${KCADM_PATH_ENV:-}" ]] && [[ -f "$KCADM_PATH_ENV" ]]; then
        KCADM_PATH="$KCADM_PATH_ENV"
        log_success "Using kcadm.sh from KCADM_PATH environment variable: $KCADM_PATH"
        return 0
    fi
    
    # Check common installation locations
    local common_paths=(
        "/opt/keycloak/bin/kcadm.sh"
        "/usr/local/keycloak/bin/kcadm.sh"
        "/home/$(whoami)/keycloak/bin/kcadm.sh"
        "$HOME/keycloak/bin/kcadm.sh"
        "./keycloak/bin/kcadm.sh"
    )
    
    for path in "${common_paths[@]}"; do
        if [[ -f "$path" ]]; then
            KCADM_PATH="$path"
            log_success "Found kcadm.sh at: $KCADM_PATH"
            return 0
        fi
    done
    
    # kcadm.sh not found, offer to install
    log_warning "kcadm.sh not found in PATH or common locations"
    echo
    echo "Keycloak Admin CLI (kcadm.sh) is required but not found."
    echo "Would you like to install it automatically?"
    echo
    read -p "Install Keycloak Admin CLI? [Y/n]: " install_choice
    
    if [[ "$install_choice" =~ ^[Nn]$ ]]; then
        log_error "Keycloak Admin CLI is required to continue"
        log_info "Please install Keycloak or set KCADM_PATH environment variable"
        exit 1
    fi
    
    install_keycloak_cli
}

# Install Keycloak Admin CLI
install_keycloak_cli() {
    log_info "Installing Keycloak Admin CLI..."
    
    local os_type=$(detect_os)
    local keycloak_version="26.3.2"  # Latest stable version
    local install_dir="${KEYCLOAK_INSTALL_DIR:-/opt/keycloak}"
    local temp_dir="/tmp/keycloak-install-$$"
    
    # Determine download URL based on OS
    local download_url
    case "$os_type" in
        linux|macos)
            download_url="https://github.com/keycloak/keycloak/releases/download/${keycloak_version}/keycloak-${keycloak_version}.tar.gz"
            ;;
        windows)
            download_url="https://github.com/keycloak/keycloak/releases/download/${keycloak_version}/keycloak-${keycloak_version}.zip"
            ;;
        *)
            log_error "Unsupported operating system: $os_type"
            exit 1
            ;;
    esac
    
    log_info "Detected OS: $os_type"
    log_info "Keycloak version: $keycloak_version"
    log_info "Install directory: $install_dir"
    log_info "Download URL: $download_url"
    
    # Check if we need sudo for installation
    local use_sudo=""
    if [[ "$install_dir" == /opt/* ]] || [[ "$install_dir" == /usr/* ]]; then
        if [[ $EUID -ne 0 ]]; then
            log_info "Installation to system directory requires sudo privileges"
            use_sudo="sudo"
        fi
    fi
    
    # Create temporary directory
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Determine file extension and archive name
    local file_extension
    local archive_file
    case "$os_type" in
        linux|macos)
            file_extension="tar.gz"
            archive_file="keycloak.tar.gz"
            ;;
        windows)
            file_extension="zip"
            archive_file="keycloak.zip"
            ;;
    esac
    
    # Download Keycloak
    log_info "Downloading Keycloak ${keycloak_version}..."
    if command -v curl &> /dev/null; then
        if curl -L -o "$archive_file" "$download_url"; then
            log_success "Download completed: $archive_file"
        else
            log_error "Download failed"
            cleanup_temp_install
            exit 1
        fi
    elif command -v wget &> /dev/null; then
        if wget -O "$archive_file" "$download_url"; then
            log_success "Download completed: $archive_file"
        else
            log_error "Download failed"
            cleanup_temp_install
            exit 1
        fi
    else
        log_error "Neither curl nor wget found. Please install one of them."
        cleanup_temp_install
        exit 1
    fi
    
    # Verify download
    if [[ ! -f "$archive_file" ]]; then
        log_error "Downloaded file not found: $archive_file"
        cleanup_temp_install
        exit 1
    fi
    
    local file_size=$(du -h "$archive_file" | cut -f1)
    log_info "Downloaded file size: $file_size"
    
    # Extract archive
    log_info "Extracting Keycloak from $archive_file..."
    case "$os_type" in
        linux|macos)
            if tar -xzf "$archive_file"; then
                log_success "Extraction completed"
            else
                log_error "Extraction failed"
                cleanup_temp_install
                exit 1
            fi
            ;;
        windows)
            if command -v unzip &> /dev/null; then
                if unzip -q "$archive_file"; then
                    log_success "Extraction completed"
                else
                    log_error "Extraction failed"
                    cleanup_temp_install
                    exit 1
                fi
            else
                log_error "unzip command not found. Please install unzip."
                cleanup_temp_install
                exit 1
            fi
            ;;
    esac
    
    # Verify extraction
    if [[ ! -d "keycloak-${keycloak_version}" ]]; then
        log_error "Extracted directory not found: keycloak-${keycloak_version}"
        log_info "Available files/directories:"
        ls -la
        cleanup_temp_install
        exit 1
    fi
    
    # Create installation directory
    log_info "Creating installation directory: $install_dir"
    $use_sudo mkdir -p "$install_dir"
    
    # Move extracted files to installation directory
    log_info "Installing Keycloak to: $install_dir"
    $use_sudo cp -r keycloak-${keycloak_version}/* "$install_dir/"
    
    # Set executable permissions
    $use_sudo chmod +x "$install_dir/bin/kcadm.sh"
    $use_sudo chmod +x "$install_dir/bin/kc.sh"
    
    # Set KCADM_PATH
    KCADM_PATH="$install_dir/bin/kcadm.sh"
    
    # Add to PATH for current session
    export PATH="$install_dir/bin:$PATH"
    
    # Offer to add to shell profile
    add_to_shell_profile "$install_dir/bin"
    
    # Cleanup
    cleanup_temp_install
    
    # Verify installation
    if [[ -f "$KCADM_PATH" ]]; then
        log_success "Keycloak Admin CLI installed successfully!"
        log_info "Location: $KCADM_PATH"
        log_info "Version: $($KCADM_PATH --version 2>/dev/null || echo 'Unknown')"
    else
        log_error "Installation failed - kcadm.sh not found at expected location"
        exit 1
    fi
}

# Add Keycloak bin directory to shell profile
add_to_shell_profile() {
    local bin_dir="$1"
    local shell_name=$(basename "$SHELL")
    local profile_file=""
    
    case "$shell_name" in
        bash)
            if [[ -f "$HOME/.bashrc" ]]; then
                profile_file="$HOME/.bashrc"
            elif [[ -f "$HOME/.bash_profile" ]]; then
                profile_file="$HOME/.bash_profile"
            fi
            ;;
        zsh)
            profile_file="$HOME/.zshrc"
            ;;
        fish)
            profile_file="$HOME/.config/fish/config.fish"
            ;;
    esac
    
    if [[ -n "$profile_file" ]]; then
        echo
        read -p "Add Keycloak to your PATH permanently in $profile_file? [Y/n]: " add_path_choice
        
        if [[ ! "$add_path_choice" =~ ^[Nn]$ ]]; then
            local path_line="export PATH=\"$bin_dir:\$PATH\"  # Added by Keycloak installation script"
            
            # Check if already added
            if ! grep -q "# Added by Keycloak installation script" "$profile_file" 2>/dev/null; then
                echo "" >> "$profile_file"
                echo "# Keycloak Admin CLI" >> "$profile_file"
                echo "$path_line" >> "$profile_file"
                log_success "Added Keycloak to PATH in $profile_file"
                log_info "Run 'source $profile_file' or restart your terminal to use kcadm.sh from anywhere"
            else
                log_info "Keycloak PATH already exists in $profile_file"
            fi
        fi
    fi
}

# Cleanup temporary installation files
cleanup_temp_install() {
    if [[ -n "$temp_dir" ]] && [[ -d "$temp_dir" ]]; then
        rm -rf "$temp_dir"
        log_info "Cleaned up temporary files"
    fi
}

# Check Java installation and provide guidance
check_java_installation() {
    log_info "Checking Java installation..."
    
    local java_cmd=""
    local java_version=""
    
    # Check for java command
    if command -v java &> /dev/null; then
        java_cmd="java"
    elif command -v /usr/bin/java &> /dev/null; then
        java_cmd="/usr/bin/java"
    elif [[ -n "${JAVA_HOME:-}" ]] && [[ -f "$JAVA_HOME/bin/java" ]]; then
        java_cmd="$JAVA_HOME/bin/java"
    fi
    
    if [[ -n "$java_cmd" ]]; then
        # Get Java version
        java_version=$($java_cmd -version 2>&1 | head -n1 | cut -d'"' -f2)
        log_success "Java found: $java_cmd"
        log_info "Java version: $java_version"
        
        # Check if Java version is compatible (Java 17 or higher for Keycloak 26.3.2+)
        local major_version=$(echo "$java_version" | cut -d'.' -f1)
        if [[ "$major_version" -ge 17 ]] 2>/dev/null; then
            log_success "Java version is compatible (17+)"
            return 0
        elif [[ "$major_version" -ge 11 ]] 2>/dev/null; then
            log_warning "Java version $java_version is not compatible with Keycloak 26.3.2"
            log_warning "Keycloak 26.3.2+ requires Java 17 or higher (you have Java $major_version)"
            log_warning "Class file version error will occur with Java $major_version"
            echo
            read -p "Upgrade to Java 17 now? [Y/n]: " upgrade_choice
            if [[ ! "$upgrade_choice" =~ ^[Nn]$ ]]; then
                install_java
                return 0
            else
                log_error "Java 17+ is required to continue"
                show_java_installation_guide
                exit 1
            fi
        else
            log_warning "Java version $java_version is not compatible with Keycloak"
            log_warning "Keycloak requires Java 17 or higher"
            echo
            read -p "Continue anyway? [y/N]: " continue_choice
            if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                log_info "Please upgrade Java to version 17 or higher"
                show_java_installation_guide
                exit 1
            fi
        fi
    else
        log_error "Java is not installed or not found in PATH"
        log_error "Keycloak Admin CLI requires Java 17 or higher to run"
        echo
        show_java_installation_guide
        echo
        read -p "Install Java now? [Y/n]: " install_java_choice
        
        if [[ ! "$install_java_choice" =~ ^[Nn]$ ]]; then
            install_java
        else
            log_error "Java is required to continue"
            exit 1
        fi
    fi
}

# Show Java installation guide
show_java_installation_guide() {
    echo "======================================================================"
    echo "Java Installation Guide"
    echo "======================================================================"
    echo
    echo "Ubuntu/Debian:"
    echo "  sudo apt update"
    echo "  sudo apt install openjdk-17-jdk"
    echo
    echo "CentOS/RHEL 8+:"
    echo "  sudo dnf install java-17-openjdk-devel"
    echo
    echo "CentOS/RHEL 7:"
    echo "  sudo yum install java-17-openjdk-devel"
    echo
    echo "macOS:"
    echo "  brew install openjdk@17"
    echo "  # Or download from: https://adoptium.net/"
    echo
    echo "Amazon Linux 2:"
    echo "  sudo amazon-linux-extras install java-openjdk17"
    echo
    echo "Amazon Linux 2023:"
    echo "  sudo yum install java-17-amazon-corretto-devel"
    echo
    echo "Manual Installation:"
    echo "  1. Download OpenJDK 17+ from: https://adoptium.net/"
    echo "  2. Extract and set JAVA_HOME environment variable"
    echo "  3. Add \$JAVA_HOME/bin to your PATH"
    echo
    echo "Note: Keycloak 26.3.2+ requires Java 17 minimum"
    echo "      Java 11 will cause UnsupportedClassVersionError"
    echo
    echo "======================================================================"
}

# Attempt to install Java automatically
install_java() {
    log_info "Attempting to install Java..."
    
    local os_type=$(detect_os)
    local install_cmd=""
    
    case "$os_type" in
        linux)
            # Detect Linux distribution
            if command -v apt-get &> /dev/null; then
                # Debian/Ubuntu
                install_cmd="sudo apt update && sudo apt install -y openjdk-17-jdk"
            elif command -v dnf &> /dev/null; then
                # Fedora/RHEL 8+
                install_cmd="sudo dnf install -y java-17-openjdk-devel"
            elif command -v yum &> /dev/null; then
                # CentOS/RHEL 7 and Amazon Linux
                if grep -q "Amazon Linux 2023" /etc/os-release 2>/dev/null; then
                    install_cmd="sudo yum install -y java-17-amazon-corretto-devel"
                elif grep -q "Amazon Linux 2" /etc/os-release 2>/dev/null; then
                    install_cmd="sudo amazon-linux-extras install -y java-openjdk17"
                elif grep -q "Amazon Linux" /etc/os-release 2>/dev/null; then
                    install_cmd="sudo yum install -y java-17-amazon-corretto-devel"
                else
                    install_cmd="sudo yum install -y java-17-openjdk-devel"
                fi
            else
                log_error "Unable to detect package manager for automatic Java installation"
                show_java_installation_guide
                exit 1
            fi
            ;;
        macos)
            if command -v brew &> /dev/null; then
                install_cmd="brew install openjdk@17"
            else
                log_error "Homebrew not found. Please install Java manually."
                show_java_installation_guide
                exit 1
            fi
            ;;
        *)
            log_error "Automatic Java installation not supported for this OS"
            show_java_installation_guide
            exit 1
            ;;
    esac
    
    log_info "Running: $install_cmd"
    echo
    
    if eval "$install_cmd"; then
        log_success "Java installation completed"
        
        # Verify installation
        if command -v java &> /dev/null; then
            local java_version=$(java -version 2>&1 | head -n1 | cut -d'"' -f2)
            log_success "Java is now available: $java_version"
            
            # For macOS with Homebrew, add to PATH
            if [[ "$os_type" == "macos" ]] && command -v brew &> /dev/null; then
                local java_home=$(brew --prefix openjdk@17)
                if [[ -d "$java_home" ]]; then
                    export PATH="$java_home/bin:$PATH"
                    log_info "Added Java to PATH for current session"
                    echo
                    log_info "To make this permanent, add to your shell profile:"
                    echo "export PATH=\"$java_home/bin:\$PATH\""
                fi
            fi
        else
            log_error "Java installation appeared to succeed but java command is still not available"
            log_info "You may need to restart your terminal or source your shell profile"
            exit 1
        fi
    else
        log_error "Java installation failed"
        show_java_installation_guide
        exit 1
    fi
}

# Create environment-specific export file
create_environment_export() {
    local temp_export_file="/tmp/keycloak-realm-export-${ENVIRONMENT}.json"
    
    log_info "Creating environment-specific export file..."
    
    # Use sed to replace template variables
    sed -e "s|{{REALM_NAME}}|$KEYCLOAK_REALM|g" \
        -e "s|{{FRONTEND_REDIRECT_URI}}|$FRONTEND_REDIRECT_URI|g" \
        "$EXPORT_FILE" > "$temp_export_file"
    
    # Validate JSON syntax
    if ! jq empty "$temp_export_file" 2>/dev/null; then
        log_error "Generated JSON file is invalid"
        rm -f "$temp_export_file"
        exit 1
    fi
    
    log_success "Environment-specific export file created: $temp_export_file"
    EXPORT_FILE="$temp_export_file"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if export file exists
    if [[ ! -f "$EXPORT_FILE" ]]; then
        log_error "Export file not found: $EXPORT_FILE"
        exit 1
    fi
    
    # Check if jq is available (needed for JSON processing)
    if ! command -v jq &> /dev/null; then
        log_error "jq is required but not found"
        log_info "Please install jq:"
        log_info "  Ubuntu/Debian: sudo apt-get install jq"
        log_info "  CentOS/RHEL: sudo yum install jq"
        log_info "  macOS: brew install jq"
        exit 1
    fi
    
    # Check if Java is available (required for Keycloak Admin CLI)
    check_java_installation
    
    # Setup Keycloak CLI (will install if needed)
    setup_keycloak_cli
    
    # Verify kcadm.sh is now available
    if [[ ! -f "$KCADM_PATH" ]] || [[ ! -x "$KCADM_PATH" ]]; then
        log_error "Keycloak Admin CLI setup failed"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
    log_info "Using kcadm.sh: $KCADM_PATH"
}

# Authenticate with Keycloak
authenticate() {
    log_info "Authenticating with Keycloak server..."
    
    if $KCADM_PATH config credentials \
        --server "$KEYCLOAK_SERVER_URL" \
        --realm master \
        --user "$KEYCLOAK_ADMIN_USER" \
        --password "$KEYCLOAK_ADMIN_PASSWORD"; then
        log_success "Authentication successful"
    else
        log_error "Authentication failed"
        exit 1
    fi
}

# Check if realm exists, create if not
ensure_realm_exists() {
    log_info "Checking if realm '$KEYCLOAK_REALM' exists..."
    
    if $KCADM_PATH get realms/$KEYCLOAK_REALM &> /dev/null; then
        log_success "Realm '$KEYCLOAK_REALM' already exists"
    else
        log_info "Creating realm '$KEYCLOAK_REALM'..."
        if $KCADM_PATH create realms -s realm="$KEYCLOAK_REALM" -s enabled=true; then
            log_success "Realm '$KEYCLOAK_REALM' created successfully"
        else
            log_error "Failed to create realm '$KEYCLOAK_REALM'"
            exit 1
        fi
    fi
}

# Create or update a client
create_or_update_client() {
    local client_id="$1"
    local client_config="$2"
    
    log_info "Processing client: $client_id"
    
    # Check if client already exists
    if $KCADM_PATH get clients -r "$KEYCLOAK_REALM" --fields id,clientId | grep -q "\"clientId\" : \"$client_id\""; then
        log_warning "Client '$client_id' already exists"
        
        # Get the client UUID for updates
        CLIENT_UUID=$($KCADM_PATH get clients -r "$KEYCLOAK_REALM" --fields id,clientId | \
                     jq -r ".[] | select(.clientId == \"$client_id\") | .id")
        
        log_info "Updating existing client '$client_id' (UUID: $CLIENT_UUID)"
        
        # Update the client
        if echo "$client_config" | $KCADM_PATH update clients/$CLIENT_UUID -r "$KEYCLOAK_REALM" -f -; then
            log_success "Client '$client_id' updated successfully"
        else
            log_error "Failed to update client '$client_id'"
            return 1
        fi
    else
        log_info "Creating new client '$client_id'"
        
        # Create the client
        if echo "$client_config" | $KCADM_PATH create clients -r "$KEYCLOAK_REALM" -f -; then
            log_success "Client '$client_id' created successfully"
        else
            log_error "Failed to create client '$client_id'"
            return 1
        fi
    fi
}

# Extract and process clients from export file
process_clients() {
    log_info "Processing clients from export file..."
    
    # Extract the clients array from the export file
    local clients_json
    clients_json=$(jq '.clients' "$EXPORT_FILE")
    
    if [[ "$clients_json" == "null" || "$clients_json" == "[]" ]]; then
        log_warning "No clients found in export file"
        return 0
    fi
    
    # Get the number of clients
    local client_count
    client_count=$(echo "$clients_json" | jq 'length')
    log_info "Found $client_count client(s) to process"
    
    # Process each client
    for i in $(seq 0 $((client_count - 1))); do
        local client_config
        local client_id
        
        client_config=$(echo "$clients_json" | jq ".[$i]")
        client_id=$(echo "$client_config" | jq -r '.clientId')
        
        create_or_update_client "$client_id" "$client_config"
    done
}

# Retrieve client secret for confidential clients
retrieve_client_secrets() {
    log_info "Retrieving client secrets for confidential clients..."
    
    # Get senna-backend client secret
    local backend_client_uuid
    backend_client_uuid=$($KCADM_PATH get clients -r "$KEYCLOAK_REALM" --fields id,clientId | \
                         jq -r '.[] | select(.clientId == "senna-backend") | .id')
    
    if [[ -n "$backend_client_uuid" ]]; then
        log_info "Retrieving secret for senna-backend client..."
        local client_secret
        client_secret=$($KCADM_PATH get clients/$backend_client_uuid/client-secret -r "$KEYCLOAK_REALM" | jq -r '.value')
        
        if [[ -n "$client_secret" && "$client_secret" != "null" ]]; then
            log_success "Retrieved client secret for senna-backend"
            echo "SENNA_BACKEND_CLIENT_SECRET=$client_secret"
            
            # Save to temporary file for later use
            echo "$client_secret" > /tmp/senna_backend_client_secret.txt
            log_info "Client secret saved to /tmp/senna_backend_client_secret.txt"
        else
            log_error "Failed to retrieve client secret for senna-backend"
            return 1
        fi
    else
        log_error "Could not find senna-backend client UUID"
        return 1
    fi
}

# Verify client configuration
verify_clients() {
    log_info "Verifying client configuration..."
    
    # Check senna-frontend
    if $KCADM_PATH get clients -r "$KEYCLOAK_REALM" --fields clientId,enabled,publicClient | \
       jq -e '.[] | select(.clientId == "senna-frontend" and .enabled == true and .publicClient == true)' > /dev/null; then
        log_success "senna-frontend client is properly configured"
    else
        log_error "senna-frontend client verification failed"
        return 1
    fi
    
    # Check senna-backend
    if $KCADM_PATH get clients -r "$KEYCLOAK_REALM" --fields clientId,enabled,publicClient | \
       jq -e '.[] | select(.clientId == "senna-backend" and .enabled == true and .publicClient == false)' > /dev/null; then
        log_success "senna-backend client is properly configured"
    else
        log_error "senna-backend client verification failed"
        return 1
    fi
}

# Cleanup temporary files
cleanup() {
    if [[ -f "/tmp/keycloak-realm-export-${ENVIRONMENT}.json" ]]; then
        rm -f "/tmp/keycloak-realm-export-${ENVIRONMENT}.json"
        log_info "Cleaned up temporary export file"
    fi
}

# Set trap for cleanup
trap cleanup EXIT

# Main execution
main() {
    echo "======================================================================"
    echo "Keycloak Client Configuration Script"
    echo "======================================================================"
    
    parse_arguments "$@"
    set_environment_config
    
    echo "Environment: $ENVIRONMENT"
    echo "Server: $KEYCLOAK_SERVER_URL"
    echo "Realm: $KEYCLOAK_REALM"
    echo "Frontend URI: $FRONTEND_REDIRECT_URI"
    echo "======================================================================"
    echo
    
    create_environment_export
    check_prerequisites
    prompt_for_credentials
    authenticate
    ensure_realm_exists
    process_clients
    retrieve_client_secrets
    verify_clients
    
    echo
    log_success "Keycloak client configuration completed successfully!"
    echo "======================================================================"
    echo "Environment: $ENVIRONMENT"
    echo "Next Steps:"
    echo "1. Copy the SENNA_BACKEND_CLIENT_SECRET value above"
    echo "2. Update your secrets.tfvars file with the client secret"
    echo "3. Update your Terraform configuration to create the AWS secret"
    echo "======================================================================"
}

# Run main function
main "$@"
