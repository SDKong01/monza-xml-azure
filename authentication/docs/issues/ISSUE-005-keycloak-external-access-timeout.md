# Issue Resolution Log: ISSUE-005

## Header Information
- **Date Opened**: 2025-01-27
- **Owner**: DevOps Engineer
- **Status**: Open
- **Severity**: High
- **Issue ID**: ISSUE-005
- **Title**: Keycloak External Access Connection Timeout

---

## Section 1: Problem Understanding

### Problem Statement
Keycloak admin console is accessible locally within the EC2 instance (`http://localhost:80/admin/`) but fails with connection timeout when accessed externally via public IP (`http://18.191.64.107:80/admin/`).

### Context & Background
- **Previous State**: 2 weeks ago, Keycloak was accessible externally at `http://18.191.64.107:80/admin`
- **Recent Changes**: Migrated from hardcoded credentials to AWS Secrets Manager integration
- **Current Deployment**: Fresh Docker containers with clean database after complete teardown

### Current Symptoms
- ✅ **Local Access**: `curl -I http://localhost:80/admin/` returns `HTTP/1.1 302 Found`
- ❌ **External Access**: `curl -I http://18.191.64.107:80/admin/` times out after 133754ms
- ✅ **Container Status**: All 5 containers running healthy
- ✅ **Port Mapping**: Keycloak correctly mapped `0.0.0.0:80->8080/tcp`

### Environment Details
- **EC2 Instance**: 18.191.64.107 (us-east-2)
- **Keycloak Version**: 26.3.2
- **Docker Compose**: Services running with correct port configuration
- **Security Configuration**: `KC_HTTP_ENABLED: true`, `KC_HTTPS_ENABLED: false`

### Error Evidence
```bash
ubuntu@ip-172-31-1-160:~/keystone$ curl -I http://18.191.64.107:80/admin/
curl: (28) Failed to connect to 18.191.64.107 port 80 after 133754 ms: Connection timed out
```

### Impact Assessment
- **Severity**: High - Blocks admin access and potentially all external Keycloak functionality
- **Scope**: External connectivity only; internal container networking functional
- **Dependencies**: OAuth2 Proxy and Frontend may be affected for external users

---

## Section 2: Problem Breakdown

### Core Components Analysis
1. **Network Layer**: Connection timeout suggests network-level blocking
2. **Security Groups**: AWS security group rules may be restricting port 80
3. **EC2 Instance**: Local services work, external access fails
4. **Docker Port Mapping**: Container correctly maps `0.0.0.0:80->8080`
5. **Application Layer**: Keycloak service is healthy and responding locally

### Potential Root Causes
1. **AWS Security Group**: Port 80 may not be open for inbound traffic
2. **Instance-level Firewall**: Ubuntu firewall (ufw) may be blocking port 80
3. **Network ACLs**: VPC network ACLs may have restrictive rules
4. **Route Table Issues**: Traffic routing problems in VPC
5. **Application Binding**: Docker may not be properly binding to external interface

---

## Section 3: Solution Exploration

### Option A: Check and Fix AWS Security Group Rules
**Approach**: Verify and update security group to allow port 80 inbound
- **Pros**: Most likely cause, easy to fix via AWS console/CLI
- **Cons**: None significant
- **Risk**: Low

### Option B: Investigate Instance-level Firewall
**Approach**: Check and configure Ubuntu firewall (ufw) settings
- **Pros**: Common cause of connection timeouts
- **Cons**: Requires instance-level changes
- **Risk**: Low

### Option C: Docker Network Configuration Review
**Approach**: Verify Docker daemon and container network binding
- **Pros**: Could be binding issue preventing external access
- **Cons**: More complex to diagnose and fix
- **Risk**: Medium

---

## Section 4: Implementation & Testing Log

### Iteration 1: Network Diagnostics (2025-01-27)
**Action**: Checked instance-level networking, firewall, and Docker port binding
**Rationale**: Eliminate local instance issues before checking AWS security groups

**Commands Executed**:
```bash
sudo ufw status
docker port keystone-keycloak  
sudo ss -tlnp | grep -E ':(80|8080|4181|3001|8001)'
aws ec2 describe-security-groups --group-ids $(curl -s http://169.254.169.254/latest/meta-data/security-groups/)
```

**Results**:
- ✅ **Ubuntu Firewall**: Status `inactive` - not blocking traffic
- ✅ **Docker Port Mapping**: `8080/tcp -> 0.0.0.0:80` - correctly mapped
- ✅ **Port Binding**: All services listening on `0.0.0.0` (external interface):
  - Port 80: `docker-proxy` (Keycloak)
  - Port 4181: `docker-proxy` (OAuth2 Proxy)  
  - Port 8001: `docker-proxy` (Backend)
  - Port 3001: `docker-proxy` (Frontend)
- ❌ **Security Group**: Output truncated, need complete inbound rules

**Conclusion**: Instance-level configuration is correct. Issue likely at AWS Security Group level.

**Next Action**: Get complete security group inbound rules to verify port 80 access

### Iteration 2: Security Group Fix (2025-01-27)
**Action**: Checked AWS Security Group inbound rules and added missing port 80 rule
**Rationale**: Instance-level diagnostics confirmed the issue was at AWS networking level

**Commands Executed**:
```bash
aws ec2 describe-security-groups \
  --group-ids $(curl -s http://169.254.169.254/latest/meta-data/security-groups/) \
  --query 'SecurityGroups[0].IpPermissions'
```

**Results**:
- ❌ **Root Cause Found**: Port 80 was NOT listed in security group inbound rules
- ✅ **Fix Applied**: Added port 80 inbound rule to security group via AWS console

**Action Taken**: User manually added port 80 (HTTP) inbound rule to security group

**Status**: Ready for verification testing

---

## Section 5: Final Solution & Review

### Root Cause
**Issue**: AWS Security Group was missing inbound rule for port 80 (HTTP)
**Why**: When the system was migrated to use AWS Secrets Manager, the security group configuration wasn't updated to include port 80 access

### Solution Applied
**Fix**: Added inbound rule to security group allowing port 80 traffic
- **Protocol**: TCP  
- **Port**: 80
- **Source**: 0.0.0.0/0 (or appropriate IP range)

### Verification Results
**External Access Test**: ✅ **SUCCESSFUL**
- Connection timeout resolved
- Keycloak admin console now accessible at `http://18.191.64.107/admin/`
- Security group fix working properly

### Issue Resolution Status
**Status**: ✅ **RESOLVED** - Connection timeout issue fixed

### Discovery of Related Issue
During verification, discovered a separate issue: Keycloak admin console displays "HTTPS required" message. This is a different problem from the connection timeout and requires separate investigation.

**New Issue Required**: HTTPS requirement enforcement by Keycloak application layer

### Key Takeaways
1. **Systematic Approach**: AAS Issue Resolution Process effectively isolated network vs application issues
2. **Root Cause**: Missing security group rule for port 80 
3. **Prevention**: Include port 80 in standard security group templates
4. **Documentation**: Connection issues should be diagnosed from network layer up to application layer

### Preventative Actions
1. Update security group Terraform templates to include port 80 by default
2. Create network connectivity checklist for new deployments
3. Document standard ports required for each service
