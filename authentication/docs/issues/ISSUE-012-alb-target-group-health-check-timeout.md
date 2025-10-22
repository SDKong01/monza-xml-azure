# ISSUE RESOLUTION LOG :: ISSUE-012

**Date Opened:** 2025-09-08  
**Owner:** DevOps Engineer  
**Status:** ✅ **RESOLVED**  
**Severity:** High  
**Date Resolved:** 2025-09-09  

## Issue Title
ALB Target Group Health Check Timeout Despite Working Keycloak Service

## Issue Description
The Application Load Balancer (ALB) target group continues to report the Keycloak EC2 instance as "unhealthy" with "Target.Timeout" errors, causing 504 Gateway Timeout responses to external users. However, direct testing shows the Keycloak service is fully operational and responds correctly to health check requests from within the EC2 instance.

---

## Section 1: Problem Understanding

### 1.1 Symptoms Observed
- **External Access**: `https://auth-dev.kainam.app/admin` returns 504 Gateway Timeout
- **ALB Target Health**: Shows "unhealthy" with "Target.Timeout" reason
- **Internal Service**: Keycloak responds perfectly to local requests
- **Health Check Path**: Updated from `/health/ready` to `/realms/master`

### 1.2 Error Messages/Logs
**ALB Target Health Status:**
```json
{
    "Target": {
        "Id": "i-0b53d307ca0b3c67e",
        "Port": 8080
    },
    "HealthCheckPort": "8080",
    "TargetHealth": {
        "State": "unhealthy",
        "Reason": "Target.Timeout",
        "Description": "Request timed out"
    }
}
```

**Working Internal Tests:**
```bash
# Response from EC2 instance
$ curl -I http://localhost:8080/realms/master
HTTP/1.1 200 OK
Cache-Control: no-cache
Content-Type: application/json;charset=UTF-8

$ curl -I http://10.0.101.124:8080/realms/master  
HTTP/1.1 200 OK
Cache-Control: no-cache
Content-Type: application/json;charset=UTF-8
```

### 1.3 Environment Context
- **EC2 Instance**: i-0b53d307ca0b3c67e (10.0.101.124)
- **Target Group**: kainam-keycloak-dev-tg (arn:aws:elasticloadbalancing:us-east-2:592172380963:targetgroup/kainam-keycloak-dev-tg/d6dec2d1062cca88)
- **Health Check Configuration**: 
  - Path: `/realms/master`
  - Protocol: HTTP
  - Port: 8080
  - Timeout: 5 seconds
  - Interval: 30 seconds
  - Healthy Threshold: 3
  - Expected Response: 200

### 1.4 Infrastructure Status
**✅ Working Components:**
- Keycloak container running and responsive
- Docker port mapping: `8080/tcp -> 0.0.0.0:8080`
- Security groups: ALB SG has access to EC2 port 8080
- Network connectivity: EC2 can reach itself on private IP
- Response time: 0.01 seconds (well under 5-second timeout)

**❌ Failing Components:**
- ALB health checks timing out
- External access via ALB returning 504 errors

### 1.5 Timeline
- **Previous Context**: ISSUE-011 resolved bootstrap script and database connectivity
- **Current Issue**: Discovered during admin console access testing
- **Health Check Path**: Recently updated from `/health/ready` to `/realms/master`
- **Duration**: Persisting for ~30+ minutes after configuration change

---

## Section 2: Problem Breakdown

### 2.1 Root Cause Analysis: Security Group Mismatch

**Core Issue**: The ALB security group (`sg-07444d8a1b42f2f64`) is configured to allow egress traffic only to the **Web Security Group** (`kainam-dev-web-sg`), but the Keycloak EC2 instance expects traffic from the **ALB Security Group** directly.

### 2.2 Infrastructure Mapping Discovery

**Current Configuration:**
```
ALB Security Group (sg-07444d8a1b42f2f64)
├── Ingress: HTTPS (443) from 0.0.0.0/0 ✅
└── Egress: ALL traffic to Web SG (kainam-dev-web-sg) ❌ MISMATCH

Keycloak EC2 Security Group (kainam-keycloak-dev-sg)  
├── Ingress: HTTP (8080) from ALB SG (sg-07444d8a1b42f2f64) ❌ BLOCKED
└── Egress: ALL traffic to 0.0.0.0/0 ✅
```

**The Problem Chain:**
1. ALB (`sg-07444d8a1b42f2f64`) tries to send health check to Keycloak EC2 (port 8080)
2. ALB egress rule only allows traffic to Web SG, not directly to Keycloak EC2 SG
3. Keycloak EC2 expects traffic from ALB SG, but ALB can't reach it due to egress restriction
4. Health check times out → "Target.Timeout" error

### 2.3 Network Connectivity Diagrams

**BEFORE FIX - Broken Connectivity:**
```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Internet      │    │        ALB           │    │    Keycloak EC2     │
│                 │    │ sg-07444d8a1b42f2f64 │    │ sg-0cedc4b7e413fb2ed│
│   Users         │───▶│                      │    │                     │
│                 │    │ Egress Rules:        │    │ i-0b53d307ca0b3c67e │
│ 504 Gateway     │    │ ✅ → Web SG          │────│ 10.0.101.124        │
│ Timeout ❌      │    │ ❌ → Keycloak SG     │ ❌ │                     │
│                 │    │                      │    │ Service: ✅ Running │
└─────────────────┘    └──────────────────────┘    │ Health: ❌ Timeout  │
                                                   └─────────────────────┘

Flow: Internet → ALB → ❌ BLOCKED → Keycloak EC2
Issue: ALB cannot reach Keycloak due to missing security group egress rule
```

**AFTER FIX - Restored Connectivity:**
```
┌─────────────────┐    ┌──────────────────────┐    ┌─────────────────────┐
│   Internet      │    │        ALB           │    │    Keycloak EC2     │
│                 │    │ sg-07444d8a1b42f2f64 │    │ sg-0cedc4b7e413fb2ed│
│   Users         │───▶│                      │    │                     │
│                 │    │ Egress Rules:        │    │ i-0b53d307ca0b3c67e │
│ HTTP 302        │    │ ✅ → Web SG          │    │ 10.0.101.124        │
│ Found ✅        │    │ ✅ → Keycloak SG     │───▶│                     │
│                 │    │     (TCP:8080)       │    │ Service: ✅ Running │
└─────────────────┘    └──────────────────────┘    │ Health: ✅ Healthy  │
                                                   └─────────────────────┘

Flow: Internet → ALB → ✅ CONNECTED → Keycloak EC2
Fix: Added ALB → Keycloak security group egress rule (sgr-0542e2a2fdd40804d)
```

### 2.4 Architecture Design Issue

The current security group design follows a **3-tier architecture** (ALB → Web → DB), but Keycloak EC2 was deployed with its **own dedicated security group** outside this model, creating a connectivity gap.

**Expected Flow**: ALB → Web SG → EC2 instances in Web SG  
**Actual Flow**: ALB → ❌ → Keycloak EC2 (in separate SG)

---

## Section 3: Solution Exploration

### 3.1 Solution Option A: Add ALB-to-Keycloak Egress Rule (Recommended)

**Description**: Add a specific egress rule to the ALB security group allowing traffic to the Keycloak EC2 security group.

**Implementation**:
- Add egress rule in `security-groups` module: ALB SG → Keycloak EC2 SG (port 8080)
- Keep existing ALB → Web SG rule for future web tier instances

**Pros**:
- ✅ Minimal change, surgical fix
- ✅ Maintains existing architecture patterns
- ✅ Preserves security isolation
- ✅ Quick implementation and testing

**Cons**:
- ⚠️ Creates specific coupling between ALB and Keycloak SG
- ⚠️ Requires Terraform module modification

**Risk Level**: Low

### 3.2 Solution Option B: Move Keycloak to Web Security Group

**Description**: Modify Keycloak EC2 to use the existing Web Security Group instead of its dedicated security group.

**Implementation**:
- Update `ec2-keycloak` module to use Web SG instead of creating dedicated SG
- Remove Keycloak-specific security group creation

**Pros**:
- ✅ Aligns with 3-tier architecture design
- ✅ Leverages existing ALB → Web SG connectivity
- ✅ Simplifies security group management

**Cons**:
- ❌ Higher risk change (affects EC2 instance directly)
- ❌ Web SG might have broader permissions than needed for Keycloak
- ❌ Requires EC2 instance security group replacement

**Risk Level**: Medium

### 3.3 Solution Option C: Hybrid Approach with Security Group Reference

**Description**: Keep Keycloak dedicated SG but add it as a referenced security group in ALB egress rules.

**Implementation**:
- Modify ALB module to accept additional referenced security groups
- Pass Keycloak SG ID as parameter to ALB configuration

**Pros**:
- ✅ Maintains security isolation
- ✅ Flexible for future additional services
- ✅ Clean architectural separation

**Cons**:
- ❌ More complex implementation
- ❌ Requires multiple module modifications
- ❌ Introduces new parameters and dependencies

**Risk Level**: Medium-High

---

## Section 4: Iterative Implementation and Testing

### 4.1 Chosen Solution
**Selected**: Solution A - Add dedicated ALB-to-Keycloak egress rule

**Rationale**: Follows principles of Service Isolation and Least Privilege by treating Keycloak as a dedicated "Authentication Tier" with explicit, minimal trust relationships.

### 4.2 Implementation Steps

**Stage 1-3**: Analysis and Solution Design ✅ **COMPLETE**
- Root cause identified: Security group connectivity gap
- Solution designed following AAS Issue Resolution Process

**Stage 4**: Code Validation ✅ **COMPLETE**
```bash
# Terraform formatting and validation
terraform fmt -recursive  # ✅ Code properly formatted
terraform validate        # ✅ Configuration is valid
```

**Stage 5**: Terraform Plan ✅ **COMPLETE**
```bash
terraform plan -var-file="../../secrets.tfvars"
# Plan: 1 to add, 0 to change, 0 to destroy
# ✅ Exactly the expected security group rule
```

**Stage 6**: Deployment ✅ **COMPLETE**
```bash
terraform apply -var-file="../../secrets.tfvars"
# Apply complete! Resources: 1 added, 0 changed, 0 destroyed
# ✅ Security group rule created: sgr-0542e2a2fdd40804d
```

### 4.3 Technical Implementation Details

**Resource Created**:
```hcl
resource "aws_vpc_security_group_egress_rule" "alb_to_keycloak" {
  security_group_id            = "sg-07444d8a1b42f2f64"  # ALB Security Group
  referenced_security_group_id = "sg-0cedc4b7e413fb2ed"  # Keycloak Security Group
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP traffic from ALB to Keycloak authentication service"
}
```

**File Location**: `infra-terraform/terraform/envs/dev/main.tf` (lines 772-794)

### 4.4 Testing and Validation Results

**Before Fix**:
```
Health: unhealthy | Port: 8080 | Reason: Target.Timeout | Target: i-0b53d307ca0b3c67e
```

**After Fix**:
```bash
aws elbv2 describe-target-health --target-group-arn [TARGET_GROUP_ARN]
# Result: healthy ✅
```

**End-to-End Connectivity Test**:
```bash
curl -I https://auth-dev.kainam.app/admin --connect-timeout 10
# HTTP/1.1 302 Found ✅ (Previously: 504 Gateway Timeout)
```

---

## Section 5: Final Solution & Review

### 5.1 Issue Resolution Status
**STATUS**: ✅ **RESOLVED**
**Resolution Date**: 2025-09-09
**Resolution Time**: ~2 hours (including analysis, implementation, and testing)

### 5.2 Root Cause Summary
The ALB Target Group health check timeout was caused by a **security group connectivity gap**:
- ALB security group (`sg-07444d8a1b42f2f64`) only had egress rules to the general Web security group
- Keycloak EC2 instance used a dedicated security group (`sg-0cedc4b7e413fb2ed`)
- **Missing connection**: ALB → Keycloak security group communication

### 5.3 Solution Summary
**Fix**: Added dedicated ALB-to-Keycloak egress rule
- **Type**: `aws_vpc_security_group_egress_rule`
- **Protocol**: TCP port 8080 (HTTP)
- **Direction**: ALB SG → Keycloak SG
- **Security**: Follows Least Privilege principle with minimal, explicit trust relationship

### 5.4 Business Impact
- ✅ **Service Restored**: Keycloak admin interface accessible at `https://auth-dev.kainam.app/admin`
- ✅ **Authentication Flow**: End-users can now authenticate through the application
- ✅ **Development Unblocked**: Team can proceed with authentication-dependent features
- ✅ **Infrastructure Stability**: ALB health checks passing consistently

### 5.5 Lessons Learned
1. **Security Group Design**: Dedicated services should have dedicated security groups with explicit connectivity rules
2. **Health Check Dependencies**: ALB health checks require proper network connectivity at the security group level
3. **Service Isolation**: Critical authentication services benefit from isolated security boundaries
4. **Systematic Debugging**: AAS Issue Resolution Process effectively identified root cause through methodical analysis

### 5.6 Follow-up Actions
- [ ] **Monitor**: Continue monitoring ALB target health for 24 hours to ensure stability
- [ ] **Documentation**: Update infrastructure documentation to reflect security group relationships
- [ ] **Review**: Consider applying similar security group isolation patterns to other critical services

---

## Related Documentation
- [ISSUE-011](ISSUE-011-keycloak-bootstrap-script-failure.md) - Bootstrap script resolution that preceded this issue
- [DevOps Log Entry](../agent_logs/devops_log.md#2025-09-08-alb-health-check-investigation)
- [ALB Target Groups Module](../../../infra-terraform/terraform/modules/target-groups/)
