# ISSUE-010: Certificate Common Name Invalid for auth.dev.kainam.app

## Issue Header
- **Date Opened:** 2025-01-31
- **Date Resolved:** 2025-01-31
- **Owner:** DevOps Engineer
- **Status:** Resolved
- **Severity:** High
- **Issue Type:** SSL/TLS Certificate Configuration
- **Affected System:** Authentication ALB (now auth-dev.kainam.app)
- **Resolution Time:** ~30 minutes

---

## Section 1: Problem Understanding

### Problem Statement
The domain `auth.dev.kainam.app` is returning `NET::ERR_CERT_COMMON_NAME_INVALID` in Chrome, indicating that the SSL certificate being served by the ALB does not match the requested domain name. Despite having the correct wildcard certificate (`*.kainam.app`) configured in Terraform and forcing a listener replacement, the certificate validation is still failing.

### Symptoms Observed
- **Browser Error:** `NET::ERR_CERT_COMMON_NAME_INVALID`
- **Error Message:** "Your connection is not private"
- **Domain:** `auth.dev.kainam.app`
- **Certificate Issue:** Common name mismatch during TLS handshake
- **Previous Attempts:** HTTPS listener forced replacement, certificate ARN verified

### Environment Details
- **Infrastructure:** AWS Application Load Balancer
- **Certificate:** `arn:aws:acm:us-east-2:592172380963:certificate/e50f7d6a-0701-4c27-8d32-4e6f46e875c9`
- **Certificate Domain:** `*.kainam.app` (should cover `auth.dev.kainam.app`)
- **ALB:** `kainam-auth-dev-alb-843068652.us-east-2.elb.amazonaws.com`
- **HTTPS Listener:** `arn:aws:elasticloadbalancing:us-east-2:592172380963:listener/app/kainam-auth-dev-alb/c7eec7117ce259ae/08e140ae45ec9d8d`

### Technical Context
- Terraform configuration is correct with proper certificate ARN
- DNS A record `auth.dev.kainam.app` points to ALB correctly
- Certificate is valid wildcard for `*.kainam.app`
- HTTPS listener was recently replaced to force fresh certificate binding

### Root Cause Analysis - CONFIRMED
**Certificate Scope Mismatch**: The wildcard certificate `*.kainam.app` does NOT cover second-level subdomains like `auth.dev.kainam.app`.

**Evidence:**
- Certificate Domain: `*.kainam.app` (covers `something.kainam.app`)
- Certificate SAN: `*.kainam.app`, `kainam.app`
- Requested Domain: `auth.dev.kainam.app` (requires `*.dev.kainam.app` or specific certificate)
- curl error: `SEC_E_WRONG_PRINCIPAL` - certificate subject mismatch
- DNS Resolution: ✅ Correct (points to ALB IPs: 18.216.190.236, 3.20.14.121)
- ALB Connection: ✅ Works with `-k` flag, returns 503 (no healthy targets)

### Initial Hypotheses (Updated)
1. ✅ **CONFIRMED - Certificate Subject Alternative Names (SAN):** The certificate does not include the correct pattern for second-level subdomains
2. ✅ **RULED OUT - DNS Resolution Issue:** DNS correctly resolves to ALB
3. ✅ **RULED OUT - Certificate Binding Issue:** ALB is serving the configured certificate correctly
4. ✅ **RULED OUT - Browser Cache:** Issue reproduces in curl and multiple browsers
5. ✅ **RULED OUT - Certificate Chain Issue:** Certificate chain is valid, issue is domain coverage

---

## Section 2: Problem Breakdown

### Core Issue Components

1. **Certificate Coverage Limitation**
   - Current certificate: `*.kainam.app` 
   - Covers: `anything.kainam.app` (single-level subdomains)
   - Does NOT cover: `auth.dev.kainam.app` (second-level subdomains)
   - Wildcard certificates only cover one level of subdomain

2. **Domain Architecture Mismatch**
   - Desired domain pattern: `service.environment.kainam.app`
   - Examples: `auth.dev.kainam.app`, `senna.dev.kainam.app`
   - Current certificate supports: `service.kainam.app` only

3. **Infrastructure Dependencies**
   - Terraform configuration references existing certificate
   - Certificate is shared resource (may be used by other services)
   - ALB listener configuration is correct but uses wrong certificate scope

### Technical Root Causes

1. **Wildcard Certificate Scope Rules**: RFC 6125 specifies that `*.example.com` matches `a.example.com` but NOT `a.b.example.com`
2. **Domain Strategy**: The domain strategy uses second-level subdomains which require specific certificate coverage
3. **Certificate Management**: Single wildcard certificate cannot cover the chosen domain architecture

---

## Section 3: Solution Exploration

### Option A: Request New Wildcard Certificate for *.dev.kainam.app
**Approach**: Create a new ACM certificate for `*.dev.kainam.app` to cover all dev environment services.

**Pros:**
- Covers all future dev services: `auth.dev.kainam.app`, `senna.dev.kainam.app`, etc.
- Follows the domain architecture pattern
- Future-proof for additional dev services
- Clean separation between environments

**Cons:**
- Requires DNS validation for new certificate
- Additional certificate to manage
- Terraform changes needed to reference new certificate

**Implementation Steps:**
1. Request new ACM certificate for `*.dev.kainam.app`
2. Complete DNS validation
3. Update Terraform to use new certificate ARN
4. Apply infrastructure changes

**Estimated Effort**: 1-2 hours
**Risk Level**: Low

### Option B: Add Specific Certificate for auth.dev.kainam.app
**Approach**: Request a specific certificate for just the auth domain.

**Pros:**
- Targeted solution for current issue
- No impact on other services
- Quick implementation

**Cons:**
- Will need separate certificates for each dev service
- Not scalable for future services
- More certificates to manage

**Implementation Steps:**
1. Request ACM certificate for `auth.dev.kainam.app`
2. Complete DNS validation
3. Update Terraform configuration
4. Apply changes

**Estimated Effort**: 1 hour
**Risk Level**: Low

### Option C: Change Domain Architecture to Single-Level Subdomains
**Approach**: Change domain from `auth.dev.kainam.app` to `auth-dev.kainam.app`.

**Pros:**
- Uses existing certificate
- No new certificates needed
- Immediate resolution

**Cons:**
- Changes agreed domain architecture
- Less clear environment separation
- May affect other planned services
- DNS changes required

**Implementation Steps:**
1. Update DNS records to use `auth-dev.kainam.app`
2. Update Terraform configuration
3. Apply changes

**Estimated Effort**: 30 minutes
**Risk Level**: Medium (architectural change)

---

## Section 4: Implementation and Testing Log

### Iteration 1: Domain Change Implementation
**Date**: 2025-01-31
**Action**: Changed domain from `auth.dev.kainam.app` to `auth-dev.kainam.app` to work with existing `*.kainam.app` certificate
**Rationale**: Existing certificate covers single-level subdomains (`*.kainam.app`) but not second-level subdomains (`auth.dev.kainam.app`)
**Implementation**:
- Updated Terraform locals: `auth_subdomain = "auth-dev"`, `base_domain = "kainam.app"`
- Applied terraform changes to update DNS record
**Result**: ✅ **SUCCESS** - HTTPS connection established without certificate errors
**Evidence**: `curl -I -v https://auth-dev.kainam.app` returns 503 (expected) without SSL errors
**Notes**: Resolution time: ~5 minutes, no new certificates required

---

## Section 5: Final Solution & Review

### Final Solution Summary
**Resolution**: Changed authentication domain from `auth.dev.kainam.app` to `auth-dev.kainam.app` to align with existing wildcard certificate coverage.

**Root Cause**: Wildcard certificates (`*.kainam.app`) only cover single-level subdomains per RFC 6125, not multi-level subdomains.

**Technical Details**:
- **Original Domain**: `auth.dev.kainam.app` (❌ Not covered by `*.kainam.app`)
- **New Domain**: `auth-dev.kainam.app` (✅ Covered by `*.kainam.app`)
- **Certificate**: `arn:aws:acm:us-east-2:592172380963:certificate/e50f7d6a-0701-4c27-8d32-4e6f46e875c9`
- **DNS Record**: Updated Route53 A record with alias to ALB
- **Infrastructure**: No ALB or certificate changes required

### Key Takeaways
1. **Certificate Planning**: When designing domain architecture, consider wildcard certificate limitations
2. **Domain Strategy**: Single-level subdomains (`service-environment.domain.com`) are more compatible with wildcard certificates than multi-level (`service.environment.domain.com`)
3. **Quick Validation**: Use `curl -v` to immediately verify certificate issues before browser testing
4. **RFC Compliance**: Wildcard certificates follow strict RFC 6125 rules for subdomain matching

### Preventative Actions
1. **Documentation Update**: Update domain naming conventions to prefer single-level subdomains
2. **Infrastructure Standards**: Add certificate coverage validation to Terraform planning process
3. **Testing Protocol**: Include SSL certificate validation in deployment testing checklist
4. **Knowledge Sharing**: Document wildcard certificate limitations in team knowledge base

---

## Appendix

### Related Files
- `infra-terraform/terraform/modules/alb-listeners/main.tf`
- `infra-terraform/terraform/envs/dev/main.tf`
- `authentication/docs/tasks.yml` (KEY-26-AUTH-ALB)

### Previous Actions Taken
1. Verified certificate ARN in Terraform configuration
2. Confirmed certificate domain `*.kainam.app` via AWS CLI
3. Forced HTTPS listener replacement using `terraform apply -replace`
4. Confirmed DNS A record points to correct ALB

### Error Evidence
- Screenshot showing `NET::ERR_CERT_COMMON_NAME_INVALID`
- Browser message: "auth.dev.kainam.app normally uses encryption to protect your information..."
