# ISSUE-014: SENNA SSL Certificate Invalid (ERR_CERT_COMMON_NAME_INVALID)

**Date Opened:** 2025-01-10  
**Owner:** DevOps Engineer  
**Status:** In Progress - Pending Validation  
**Severity:** High  

## Issue Summary
When accessing `senna-dev.kainam.app`, users encounter a privacy error with `net::ERR_CERT_COMMON_NAME_INVALID`. This suggests a certificate configuration mismatch between the App Runner custom domain association and the actual SSL certificate being served.

## Section 1: Problem Understanding

### Symptoms
- **Error Type:** Privacy Error / SSL Certificate Error
- **Specific Error:** `net::ERR_CERT_COMMON_NAME_INVALID`
- **Affected Service:** SENNA Frontend (senna-dev.kainam.app)
- **User Impact:** Complete inability to access SENNA application via custom domain

### Environment Context
- **Service:** kainam-senna-front-dev (AWS App Runner)
- **Domain:** senna-dev.kainam.app
- **Expected Certificate:** *.kainam.app wildcard certificate
- **Working Comparison:** auth-dev.kainam.app (working correctly)

### Initial Hypothesis
Certificate ARN mismatch between App Runner custom domain association and the actual wildcard certificate used by other services.

## Section 2: Problem Breakdown

### Root Cause Analysis
**CRITICAL FINDING**: The `aws_apprunner_custom_domain_association` resource in the App Runner module is **missing the certificate_arn parameter**.

### Technical Details
1. **App Runner Configuration** (Line 486 in dev/main.tf):
   ```hcl
   domain_certificate_arn = data.aws_acm_certificate.wildcard_kainam_app.arn
   ```
   This variable is passed to the module but **NOT used** in the actual resource.

2. **App Runner Module Resource** (modules/app-runner/main.tf:198-209):
   ```hcl
   resource "aws_apprunner_custom_domain_association" "this" {
     count = var.enable_custom_domain ? 1 : 0
   
     domain_name = var.custom_domain_name
     service_arn = aws_apprunner_service.this.arn
     # MISSING: certificate_arn = var.domain_certificate_arn
   }
   ```

3. **Working ALB Configuration** (Line 179 in dev/main.tf):
   ```hcl
   certificate_arn = data.aws_acm_certificate.wildcard_kainam_app.arn
   ```
   This correctly uses the same certificate ARN that should be used by App Runner.

### Certificate ARN Comparison
- **ALB (Working)**: Uses `data.aws_acm_certificate.wildcard_kainam_app.arn`
- **App Runner (Broken)**: Missing certificate_arn parameter entirely
- **Expected**: Both should use the same `*.kainam.app` certificate ARN

## Section 3: Solution Exploration

### Option A: Add Missing certificate_arn Parameter (RECOMMENDED)
**Description**: Add the missing `certificate_arn` parameter to the `aws_apprunner_custom_domain_association` resource.

**Implementation**:
1. Modify `infra-terraform/terraform/modules/app-runner/main.tf`
2. Add `certificate_arn = var.domain_certificate_arn` to the resource

**Pros**:
- Simple, direct fix
- Uses existing certificate infrastructure
- Consistent with ALB approach
- No infrastructure changes required

**Cons**:
- None identified

### Option B: Let App Runner Auto-Generate Certificate (NOT RECOMMENDED)
**Description**: Remove custom domain configuration and rely on App Runner's default certificate.

**Pros**:
- No certificate management

**Cons**:
- Breaks domain consistency
- Would require DNS changes
- Doesn't solve the actual problem

## Section 4: Implementation and Testing

### Iteration 1: Incorrect Solution Attempt
**Action**: Added `certificate_arn = var.domain_certificate_arn` to `aws_apprunner_custom_domain_association` resource
**Rationale**: Assumed App Runner custom domain association worked like ALB listeners
**Result**: ❌ FAILED - Terraform validation error: "An argument named 'certificate_arn' is not expected here"
**Notes**: This approach was based on incorrect assumption about App Runner certificate management

### Iteration 2: AWS Documentation Research
**Action**: Researched AWS Terraform Provider documentation using Context7
**Rationale**: Need to understand correct App Runner custom domain configuration
**Result**: ✅ SUCCESS - Discovered key insights:

**Critical Findings**:
1. **No certificate_arn parameter**: `aws_apprunner_custom_domain_association` does NOT accept certificate_arn
2. **Automatic Certificate Management**: App Runner automatically provisions and manages SSL certificates via ACM
3. **DNS Validation Required**: After creation, CNAME records must be added to DNS for certificate validation
4. **Certificate Validation Records**: The resource outputs `certificate_validation_records` with CNAME details

**Root Cause Revision**: 
- Original hypothesis was partially correct - there IS a certificate issue
- However, the solution is NOT to add certificate_arn parameter
- The issue is likely that DNS validation records haven't been properly configured

### Iteration 3: Correct Solution Implementation
**Action**: Remove the incorrect `certificate_arn` parameter and add certificate validation records outputs
**Rationale**: App Runner manages certificates automatically, issue is likely DNS validation
**Result**: ✅ SUCCESS - Fixed Terraform configuration and discovered root cause

### Iteration 4: Root Cause Discovery
**Action**: Applied Terraform changes and retrieved certificate validation records
**Rationale**: Need to check actual certificate validation status
**Result**: ✅ SUCCESS - Found the real problem!

**Certificate Validation Records Status:**
```
senna_frontend_certificate_validation_records = [
  {
    "name" = "_30b37806550f8f3f06e240713116efc1.senna-dev.kainam.app."
    "status" = "FAILED"
    "type" = "CNAME"
    "value" = "_0cac644f22029e0bb51bebece57f30a1.xlfgrmvvlj.acm-validations.aws."
  },
  {
    "name" = "_d4d78920941274c3589f8456a5cc5cd4.2a57j788yh3tg66dfta7rkrte9mhdcl.senna-dev.kainam.app."
    "status" = "FAILED" 
    "type" = "CNAME"
    "value" = "_999033f19bff17dafc43d4a51bf1e2dd.xlfgrmvvlj.acm-validations.aws."
  }
]
```

**ROOT CAUSE CONFIRMED**: DNS validation records are not properly configured in Route 53, causing certificate validation to fail.

## Section 5: Final Solution & Review

### Root Cause Summary
The SSL certificate error `ERR_CERT_COMMON_NAME_INVALID` occurs because:

1. **App Runner Custom Domain**: `senna-dev.kainam.app` is correctly configured
2. **Certificate Management**: App Runner automatically provisions SSL certificates via ACM
3. **DNS Validation Failure**: The certificate validation CNAME records are not added to Route 53
4. **Status**: Both validation records show `"status" = "FAILED"`

### Solution Required
**Add the following CNAME records to Route 53 for the `kainam.app` hosted zone:**

1. **Record 1:**
   - Name: `_30b37806550f8f3f06e240713116efc1.senna-dev.kainam.app`
   - Type: `CNAME`
   - Value: `_0cac644f22029e0bb51bebece57f30a1.xlfgrmvvlj.acm-validations.aws`

2. **Record 2:**
   - Name: `_d4d78920941274c3589f8456a5cc5cd4.2a57j788yh3tg66dfta7rkrte9mhdcl.senna-dev.kainam.app`
   - Type: `CNAME` 
   - Value: `_999033f19bff17dafc43d4a51bf1e2dd.xlfgrmvvlj.acm-validations.aws`

### Key Learnings
1. **App Runner Certificate Management**: Unlike ALB, App Runner doesn't use `certificate_arn` - it manages certificates automatically
2. **DNS Validation Required**: App Runner requires manual DNS validation record creation
3. **Certificate Status Monitoring**: Always check `certificate_validation_records` output for validation status
4. **Documentation Gap**: AWS Terraform Provider docs could be clearer about DNS validation requirements
5. **72-Hour Window**: Certificate validation records must be added within 72 hours of domain association
6. **Manual Override**: When Terraform automation fails, manual DNS record creation is the reliable fallback

### Preventative Actions
1. **Automation**: Create Terraform Route 53 records for certificate validation
2. **Monitoring**: Add alerts for certificate validation failures
3. **Documentation**: Update deployment runbooks with DNS validation steps
4. **Testing**: Include certificate validation in deployment testing checklist

## Section 6: Final Resolution Status

### Implementation Summary (2025-09-10)

**Problem Resolution Process:**
1. **Domain Re-association**: Unlinked and re-associated `senna-dev.kainam.app` to reset 72-hour validation window
2. **Manual DNS Record Creation**: Added both required certificate validation records to Route 53
3. **Terraform State Cleanup**: Removed automated validation records from Terraform state to prevent conflicts
4. **Configuration Update**: Disabled automatic validation record creation in Terraform

**DNS Validation Records Created:**
```
Record 1: _30b37806550f8f3f06e240713116efc1.senna-dev.kainam.app
→ _0cac644f22029e0bb51bebece57f30a1.xlfgrmvvlj.acm-validations.aws
Status: SUCCESS ✅

Record 2: _d4d78920941274c3589f8456a5cc5cd4.2a57j788yh3tg66dfta7rkrte9mhdcl.senna-dev.kainam.app  
→ _999033f19bff17dafc43d4a51bf1e2dd.xlfgrmvvlj.acm-validations.aws
Status: PENDING_VALIDATION 🔄
```

**Current Status:**
- **Domain Association**: Active (`pending_certificate_dns_validation`)
- **Validation Progress**: 1 of 2 records validated successfully
- **Expected Completion**: Certificate validation in progress, monitoring required
- **Access Status**: `https://senna-dev.kainam.app` - awaiting full validation

**Terraform State:**
- ✅ Validation record resources removed from state
- ✅ Configuration updated to disable automatic validation
- ⏳ Apply pending to sync outputs with current AWS status

### Final Status: **IN PROGRESS - PENDING VALIDATION COMPLETION**

**Next Steps:**
1. Monitor second validation record completion
2. Test HTTPS access once both records show SUCCESS
3. Apply Terraform configuration to sync state
4. Update DevOps log with final resolution
