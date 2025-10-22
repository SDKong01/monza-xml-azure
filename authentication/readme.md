# Keystone Authentication

## Project Overview

Keystone Authentication is a production-ready, enterprise-grade authentication and authorization gateway built for the Kainam Platform. It provides a secure, centralized access control system that protects Kainam's APIs and frontend applications using industry-standard OAuth2/OIDC protocols.

The system solves the complex challenge of implementing secure, scalable authentication across multiple environments (local development, staging, production) while maintaining security best practices like secrets management, gateway isolation, and role-based access control. Unlike traditional authentication solutions that require extensive custom integration, Keystone Authentication provides a ready-to-deploy gateway architecture that seamlessly integrates with existing applications through proven reverse proxy patterns and standard HTTP headers.

## Table of Contents

- [Project Overview](#project-overview)
- [Get Started](#get-started)
  - [Prerequisites](#prerequisites)
  - [Local Development Setup](#local-development-setup)
  - [AWS EC2 Production Setup](#aws-ec2-production-setup)
- [Usage](#usage)
  - [Authentication Flow](#authentication-flow)
  - [Testing](#testing)
  - [Accessing Protected Resources](#accessing-protected-resources)
- [Tech We Use](#tech-we-use)
- [Features](#features)
- [Developer Notes](#developer-notes)

## Get Started

### Prerequisites

#### For Authentication System Deployment

- **Docker** (version 20.0+) and **Docker Compose** (version 2.0+)
- **Git** for cloning the repository
- For AWS EC2 deployment:
  - AWS CLI v2 configured with appropriate credentials
  - EC2 instance with IAM role permissions for Secrets Manager
  - `jq` for JSON parsing in shell scripts

#### For Keycloak Theme Development

To build and customize the Keycloak login theme with Kainam branding:

- **Node.js** (version 18.0+ or 20.0+)
  ```bash
  # Check Node.js version
  node --version
  
  # Install Node.js (Windows with Chocolatey)
  choco install nodejs-lts -y
  ```

- **Yarn Package Manager**
  ```bash
  # Install Yarn globally
  npm install -g yarn
  
  # Verify installation
  yarn --version
  ```

- **Java JDK 17 (LTS)** - Required for Maven/Keycloakify build process
  ```bash
  # Install Java 17 (Windows with Chocolatey)
  choco install temurin17 -y
  
  # Verify installation
  java -version
  
  # Set JAVA_HOME (PowerShell as Administrator)
  [System.Environment]::SetEnvironmentVariable("JAVA_HOME", "C:\Program Files\Eclipse Adoptium\jdk-17.0.16.8-hotspot", [System.EnvironmentVariableTarget]::Machine)
  ```

- **Apache Maven** - Required for packaging Keycloak themes into JAR files
  ```bash
  # Install Maven (Windows with Chocolatey)
  choco install maven -y
  
  # Verify installation
  mvn --version
  ```

- **Frontend Dependencies** (automatically installed via Yarn):
  - React 18.2+
  - Tailwind CSS 3.4+
  - Vite 5.0+
  - Keycloakify 11.9+
  - TypeScript 5.2+

### Local Development Setup

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd authentication/
   ```

2. **Start the authentication system:**
   ```bash
   docker-compose -f docker-compose-local.yml --env-file local.env up -d
   ```

3. **Verify all services are running:**
   ```bash
   docker-compose -f docker-compose-local.yml ps
   ```

4. **Access the application:**
   - **Frontend:** http://localhost (NGINX Gateway)
   - **Keycloak Admin:** http://localhost:81/admin (admin/admin)
   - **Protected API:** http://localhost/api/v1/me (requires authentication)

### AWS EC2 Production Setup

1. **Ensure IAM role permissions:**
   Your EC2 instance needs the `keystone-ec2-role` with Secrets Manager access.

2. **Clone and configure:**
   ```bash
   git clone <repository-url>
   cd authentication/
   ```

3. **Start with secrets management:**
   ```bash
   # Uses start_keystone.sh to fetch AWS secrets and start services
   bash scripts/start_keystone.sh
   ```

4. **Verify deployment:**
   ```bash
   docker-compose ps
   # All services should show "healthy" status
   ```

5. **Access the production application:**
   - **Frontend:** http://YOUR_EC2_IP:81
   - **Keycloak Admin:** http://YOUR_EC2_IP:80/admin
   - **Protected API:** http://YOUR_EC2_IP:81/api/v1/me

### Keycloak Theme Development & Build

The Keycloak login theme uses **Keycloakify** to create a custom React-based theme with Kainam branding.

1. **Navigate to the theme directory:**
   ```bash
   cd authentication/keycloak-theme/
   ```

2. **Install dependencies:**
   ```bash
   yarn install
   ```

3. **Development mode (with hot reload):**
   ```bash
   yarn dev
   # Access at http://localhost:5173
   # Note: Will show "No Keycloak Context" - this is expected outside Keycloak
   ```

4. **Build the theme JAR:**
   ```bash
   yarn build-keycloak-theme
   ```
   This generates two JAR files in `dist_keycloak/`:
   - `keycloak-theme-for-kc-22-to-25.jar` - For Keycloak 22-25
   - `keycloak-theme-for-kc-all-other-versions.jar` - For older versions

5. **Deploy theme to Keycloak:**
   
   **Requirements:**
   - JAR file with custom theme (built from step 4)
   - Docker image with JAR copied deployed into Keycloak
   
   **After deployment, activate the theme in Keycloak Admin Console:**
   
   1. Navigate to the Keycloak Admin Console: `https://auth-dev.kainam.app/admin`
   2. Select your realm from the dropdown (e.g., `kainam-dev`)
   3. Go to **Realm Settings** in the left sidebar
   4. Click on the **Themes** tab
   5. In the **Login Theme** dropdown, select `kainam`
   6. Click **Save**
   
   **Verification:**
   - Visit the login page: `https://auth-dev.kainam.app/realms/kainam-dev/protocol/openid-connect/auth?client_id=account-console`
   - You should see the Kainam branded login page with custom colors, logo, and styling

## Usage

### Authentication Flow

1. **Access the frontend application:**
   Navigate to your NGINX gateway URL (localhost for local, EC2 IP:81 for production)

2. **Login process:**
   - Click "Login" button on the frontend
   - You'll be redirected to Keycloak for authentication
   - Enter your credentials (local: test.user@kainam.ai/Test@123, EC2: pf@kainam.ai/abc123)
   - After successful login, you'll be redirected back to the application

3. **Access protected resources:**
   Once authenticated, you can access protected API endpoints like `/api/v1/me`

### Testing

**Run the comprehensive test suite:**

```bash
# Local environment testing
bash tests/foundational_robustness/gateway_test.sh local

# AWS EC2 environment testing  
bash tests/foundational_robustness/gateway_test.sh aws-dev
```

**Manual testing with curl:**

```bash
# Test unauthenticated access (should redirect)
curl -v http://localhost/api/v1/me

# Test direct OAuth2-proxy access (should be blocked)
curl -v http://localhost:4180/api/v1/me

# Test frontend access (should return HTML)
curl -v http://localhost/
```

### Accessing Protected Resources

**For applications integrating with Keystone Authentication:**

Your backend services will receive authenticated user information through HTTP headers:

```http
X-Forwarded-Email: user@example.com
X-Forwarded-Preferred-Username: john.doe
X-User-Roles: admin,user
X-Access-Token: eyJhbGciOiJSUzI1NiIs...
```

**API Integration Example:**

```python
# Example FastAPI endpoint that receives user identity
@app.get("/api/v1/me")
async def get_current_user(
    user_email: str = Header(None, alias="X-Forwarded-Email"),
    user_name: str = Header(None, alias="X-Forwarded-Preferred-Username"),
    user_roles: str = Header(None, alias="X-User-Roles")
):
    return {
        "email": user_email,
        "username": user_name,
        "roles": user_roles.split(",") if user_roles else [],
        "authenticated": True
    }
```

### To Deactivate Keycloak SSL requirement

Turn off the SSL requirement on the master realm via kcadm.sh

1. Exec into the keycloak container and use kcadm.sh:

```bash
docker exec -it keystone-keycloak /bin/bash
```

2. Inside the container, login to the admin API
```bash
 /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user "$KEYCLOAK_ADMIN" \
  --password "$KEYCLOAK_ADMIN_PASSWORD"
```

3. Set the SSL mode for the master realm to NONE (allows HTTP from anywhere)

```bash
 /opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
 ```

 Note: This is only in deveopment. In production, we should use SSL.

## Tech We Use

### Core Technologies
- **NGINX** - Reverse proxy and API gateway with auth_request module
- **OAuth2-Proxy** - Authentication proxy for OAuth2/OIDC integration
- **Keycloak** - Identity and access management, OIDC provider
- **Docker & Docker Compose** - Containerization and orchestration

### Backend & Frontend
- **FastAPI** - Python web framework for backend API services
- **Next.js** - React-based frontend framework
- **PostgreSQL** - Database for Keycloak user storage

### Theme Development
- **Keycloakify** - React-to-Keycloak theme converter
- **React** - UI component library for theme development
- **Tailwind CSS** - Utility-first CSS framework for styling
- **Vite** - Fast frontend build tool and dev server
- **TypeScript** - Type-safe JavaScript development
- **Apache Maven** - Java build tool for JAR packaging

### Infrastructure & DevOps
- **AWS Secrets Manager** - Secure credentials storage
- **AWS IAM** - Role-based permissions for EC2 instances
- **AWS EC2** - Production deployment environment
- **Bash Scripting** - Automation and deployment scripts

### Development Tools
- **Git** - Version control
- **curl** - API testing and validation
- **jq** - JSON parsing in shell scripts

### Security & Standards
- **OAuth2/OIDC** - Industry-standard authentication protocols
- **JWT** - JSON Web Tokens for secure information transmission
- **Docker Health Checks** - Service monitoring and reliability 

## Features

### 🔐 Security & Authentication
- **OAuth2/OIDC Integration** - Industry-standard authentication protocols
- **Gateway Isolation** - OAuth2-proxy secured behind NGINX (no direct external access)
- **Token Validation** - Automatic JWT token verification and user identity injection
- **Session Management** - Secure cookie-based session handling with configurable expiration
- **Role-Based Access Control** - User roles and permissions through Keycloak integration

### 🏗️ Architecture & Infrastructure
- **NGINX Gateway Pattern** - Single entry point for all application traffic
- **Microservices Ready** - Header-based user identity forwarding to backend services
- **Multi-Environment Support** - Separate configurations for local development and production
- **Container Orchestration** - Docker Compose for reliable service management
- **Health Monitoring** - Built-in health checks for all services

### ☁️ AWS Integration
- **Secrets Management** - AWS Secrets Manager integration with IAM role authentication
- **EC2 Deployment** - Production-ready deployment scripts for AWS EC2
- **Infrastructure as Code** - Terraform-compatible configuration management
- **Automated Startup** - Self-configuring deployment with secrets injection

### 🧪 Testing & Validation
- **Comprehensive Test Suite** - Automated testing for gateway protection scenarios
- **Multi-Environment Testing** - Validation across local and production environments
- **Security Testing** - OAuth2 flow validation and isolation verification
- **Issue Resolution Framework** - Systematic debugging and documentation process

### 🔧 Developer Experience
- **Easy Setup** - One-command deployment for both local and production
- **Clear Documentation** - Comprehensive guides and troubleshooting resources
- **Flexible Configuration** - Environment-specific settings and easy customization
- **API Integration Examples** - Ready-to-use code samples for backend integration