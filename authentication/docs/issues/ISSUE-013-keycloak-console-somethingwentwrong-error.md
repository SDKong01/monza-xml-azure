# ISSUE RESOLUTION LOG :: ISSUE-013

**Date Opened:** 2025-09-09  
**Owner:** DevOps Engineer  
**Status:** RESOLVED  
**Date Resolved:** 2025-09-09  
**Severity:** High  

## Issue Title
Keycloak Console "somethingWentWrong" Error on Admin Interface Access

## Issue Description
After successfully resolving ISSUE-012 (ALB Target Group Health Check Timeout), the Keycloak admin console is now accessible externally but displays a generic "somethingWentWrong" error when attempting to access the admin interface. The error appears to be a client-side application error rather than a connectivity issue.

---

## Section 1: Problem Understanding

### 1.1 Symptoms and Error Messages

**Primary Symptom:**
- ❌ **Error Display**: "somethingWentWrong" error message with "somethingWentWrongDescription" text
- ❌ **User Interface**: Generic error screen with "tryAgain" button
- ✅ **Network Connectivity**: Successfully resolved from ISSUE-012 - ALB health checks passing
- ✅ **External Access**: `https://auth-dev.kainam.app/admin` returns HTTP responses (no more 504 timeouts)

**Error Context:**
```
URL: https://auth-dev.kainam.app/admin
Response: HTTP 200/302 (connectivity working)
Display: Generic "somethingWentWrong" error page
Browser: Error appears in web interface
```

### 1.2 Environment and Infrastructure Status

**Current Infrastructure State:**
- ✅ **ALB Health**: Target group showing "healthy" status
- ✅ **EC2 Instance**: Keycloak service running (i-0b53d307ca0b3c67e)
- ✅ **Security Groups**: ALB-to-Keycloak connectivity established (sgr-0542e2a2fdd40804d)
- ✅ **Network Flow**: Internet → ALB → Keycloak EC2 working
- ❌ **Application Layer**: Keycloak admin console showing application error

**Infrastructure Details:**
```
Environment: dev
ALB: kainam-auth-dev-alb (sg-07444d8a1b42f2f64)
Keycloak EC2: i-0b53d307ca0b3c67e (sg-0cedc4b7e413fb2ed)
Service URL: https://auth-dev.kainam.app/admin
Health Check: /realms/master (passing)
```

### 1.3 Timeline and Context

**Issue Timeline:**
- **2025-09-09 ~15:00**: ISSUE-012 resolved - ALB connectivity restored
- **2025-09-09 ~17:00**: External access confirmed working (HTTP 302 responses)
- **2025-09-09 ~17:30**: User attempts to access admin console
- **2025-09-09 ~17:30**: "somethingWentWrong" error discovered

**Related Context:**
- **Previous Issue**: ISSUE-012 (ALB Target Group Health Check Timeout) - ✅ RESOLVED
- **Infrastructure Changes**: Security group rule added for ALB-to-Keycloak connectivity
- **Service Status**: Keycloak service appears to be running but may have configuration issues

### 1.4 Impact Assessment

**Business Impact:**
- ❌ **Admin Access**: Keycloak administrators cannot access admin console
- ❌ **User Management**: Cannot manage users, roles, or authentication settings
- ❌ **Development Blocked**: Authentication configuration changes impossible
- ✅ **End-User Auth**: Unknown - need to test if user authentication flows work

**Technical Impact:**
- **Severity**: High (admin functionality completely inaccessible)
- **Scope**: Keycloak admin console functionality
- **Urgency**: High (blocks authentication management tasks)

---

## Section 2: Problem Breakdown

### 2.1 Investigation Results

**Docker Container Analysis:**
- ✅ **Service Status**: Keycloak application is running and responding (HTTP 200 OK)
- ✅ **Local Connectivity**: `curl http://localhost:8080/realms/master` returns valid JSON response
- ❌ **Health Check**: Docker container marked as "unhealthy" due to missing `curl` command in container image
- ❌ **Health Check Failure**: Container health check fails with "curl: command not found"

**Key Findings:**
```bash
# Container Status
CONTAINER STATUS: Up 17 hours (unhealthy)
FAILING STREAK: 2069 failed health checks

# Health Check Error
ExitCode: 1
Output: "/bin/sh: line 1: curl: command not found"

# Application Response (Local Test)
HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8
Response: Valid Keycloak realm configuration JSON
```

### 2.2 Root Cause Analysis

**Primary Issue**: Docker Health Check Misconfiguration
- The Docker container health check is configured to use `curl` command
- The Keycloak Docker image does not include `curl` utility
- Health check failures cause the container to be marked "unhealthy"
- This may impact ALB health checks or application behavior

**Primary Issue**: Hostname/Port Redirection Misconfiguration
- Keycloak is configured with `KC_HOSTNAME=auth-dev.kainam.app` but redirects include port 8080
- External access: `https://auth-dev.kainam.app:443/admin` (via ALB)
- Internal redirect: `http://auth-dev.kainam.app:8080/admin/master/console/` (direct to container)
- Browser cannot access port 8080 externally → "somethingWentWrong" error

### 2.3 Docker Logs Analysis

**Startup Sequence (from logs):**
1. ✅ **Database Connection**: Successfully connected to PostgreSQL
2. ✅ **Schema Initialization**: Database schema initialized successfully  
3. ✅ **Service Startup**: Keycloak started on port 8080 (32.127s startup time)
4. ✅ **Admin User**: Temporary admin user created with username "admin-cli"
5. ⚠️ **Warnings**: Deprecated environment variables and hostname configuration warnings

**Configuration Warnings:**
```
WARNING: Hostname v1 options [proxy, hostname-strict-https] are still in use
WARNING: Likely misconfiguration detected. With HTTPS not enabled, `proxy-headers` 
unset, and a non-URL `hostname`, the server is running in an insecure context
```

### 2.4 Definitive Root Cause Analysis

**Environment Variable Analysis:**
```bash
KC_HOSTNAME=auth-dev.kainam.app
KC_HOSTNAME_STRICT=false
KC_HOSTNAME_STRICT_HTTPS=false
KC_HTTP_ENABLED=true
KC_PROXY=edge
```

**Redirect Flow Analysis:**
1. **External Request**: `https://auth-dev.kainam.app/admin` (port 443 via ALB)
2. **ALB Routes**: Request to Keycloak container port 8080
3. **Keycloak Redirect**: `Location: http://auth-dev.kainam.app:8080/admin/master/console/`
4. **Browser Attempt**: Tries to access `http://auth-dev.kainam.app:8080` (BLOCKED - port not accessible externally)
5. **Result**: "somethingWentWrong" error due to failed redirect

**The Problem**: Keycloak's hostname configuration doesn't account for the ALB proxy setup, causing redirects to include the internal port 8080 instead of the external HTTPS port 443.

---

## Section 3: Solution Exploration

### 3.1 Solution Option A: Fix Keycloak Hostname Configuration (Recommended)

**Description**: Update Keycloak environment variables to properly handle ALB proxy setup.

**Implementation**:
- Set `KC_HOSTNAME_URL=https://auth-dev.kainam.app` (full URL with HTTPS)
- Remove or update `KC_HOSTNAME` to avoid port inclusion
- Ensure `KC_PROXY=edge` is properly configured for ALB

**Pros**:
- ✅ Addresses root cause directly
- ✅ Maintains security (HTTPS redirects)
- ✅ Follows Keycloak best practices for proxy setups
- ✅ Minimal infrastructure changes required

**Cons**:
- ❌ Requires container restart
- ❌ Need to update Docker container environment variables

**Risk Level**: Low

### 3.2 Solution Option B: Fix Docker Health Check

**Description**: Update Docker health check to use a command that exists in the container.

**Implementation**:
- Replace `curl` with `wget` or native Java health check
- Or remove health check entirely if not needed

**Pros**:
- ✅ Fixes "unhealthy" container status
- ✅ Simple configuration change

**Cons**:
- ❌ Doesn't fix the main admin console issue
- ❌ Secondary priority

**Risk Level**: Very Low

### 3.3 Recommended Approach: Combined Solution

**Phase 1**: Fix Keycloak hostname configuration (Solution A)
**Phase 2**: Fix Docker health check (Solution B)

This addresses both the primary issue (admin console redirect) and secondary issue (container health status).

---

## Section 4: Iterative Implementation and Testing

### 4.1 Phase 1: Docker Health Check Fix
**Action**: Updated Dockerfile health check from `curl` to `wget`
**Result**: ✅ Container health status improved from "unhealthy" to "starting/healthy"

### 4.2 Phase 2: Keycloak Hostname Configuration
**Actions Taken**:
- Updated environment variables: `KC_HOSTNAME_URL="https://auth-dev.kainam.app"`
- Added proxy headers: `KC_PROXY_HEADERS=xforwarded`  
- Updated admin credentials: `KC_BOOTSTRAP_ADMIN_USERNAME/PASSWORD`
- Rebuilt and deployed Docker image with fixes

**Result**: ✅ External admin console access restored successfully

### 4.3 Testing and Validation
**Test Date**: 2025-09-09  
**Test Results**:
- ✅ Container running and healthy
- ✅ Local redirects working properly
- ✅ External admin console accessible at `https://auth-dev.kainam.app/admin`
- ✅ Admin interface loads without "somethingWentWrong" error

---

## Section 5: Final Solution & Review

### 5.1 Resolution Summary

**Root Causes Identified**:
1. **Docker Health Check Misconfiguration**: Dockerfile used `curl` which wasn't installed in Keycloak container
2. **Keycloak Hostname Redirection Issue**: Using deprecated `KC_HOSTNAME` instead of `KC_HOSTNAME_URL` caused incorrect redirect URLs

**Final Solution Implemented**:
1. **Docker Configuration**: Updated health check to use `wget` instead of `curl`
2. **Keycloak Configuration**: Implemented proper hostname and proxy settings:
   - `KC_HOSTNAME_URL="https://auth-dev.kainam.app"`
   - `KC_PROXY_HEADERS=xforwarded`
   - `KC_BOOTSTRAP_ADMIN_USERNAME/PASSWORD` (updated from deprecated variables)

**Files Modified**:
- `authentication/Dockerfile` - Health check fix
- `authentication/config/environments/dev/docker-compose.yml` - Environment variables
- `authentication/docs/RUNBOOK-KEYCLOAK-DEPLOYMENT.md` - Manual deployment commands
- `infra-terraform/scripts/deploy_keycloak.sh.tpl` - Bootstrap script template

### 5.2 Verification and Testing
**Resolution Date**: 2025-09-09  
**Verification Method**: External browser access to admin console  
**Status**: ✅ **FULLY RESOLVED** - Admin console accessible and functional

---

## Related Documentation
- [ISSUE-012](ISSUE-012-alb-target-group-health-check-timeout.md) - ALB connectivity issue that preceded this
- [Keycloak Deployment Runbook](../RUNBOOK-KEYCLOAK-DEPLOYMENT.md) - Deployment procedures and troubleshooting
- [DevOps Log Entry](../agent_logs/devops_log.md#2025-09-09-keycloak-console-error-investigation)
