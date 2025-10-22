# ISSUE LOG: ISSUE-009: OAuth2 Callback 500 Internal Server Error (Issuer URL Mismatch)

- **Date Opened:** 2025-08-29
- **Owner:** Backend Engineer  
- **Status:** Closed - RESOLVED
- **Severity:** High

---

## 1. Problem Understanding
*This section clearly defines the problem, its scope, and the desired outcome. It is the foundation for all subsequent analysis.*

- **What is the problem?**
  - OAuth2 authentication flow fails at callback stage with HTTP 500 Internal Server Error
  - Users can successfully login to Keycloak but callback processing fails
  - Complete authentication flow broken despite frontend now accessible (post ISSUE-008)
  - Gateway test suite Test Cases 3B and 3C fail with session authentication invalid

- **When does it happen?**
  - Occurs during Step 5 of OAuth2 flow: after successful Keycloak authentication, during `/oauth2/callback` processing
  - Happens when OAuth2-proxy attempts to verify the ID token returned by Keycloak
  - Consistently reproducible on every authentication attempt

- **Where does it happen?**
  - Environment: EC2 production (docker-compose.yml with ec2.env)
  - Components: OAuth2-proxy callback verification → Keycloak token validation
  - Specific endpoint: `/oauth2/callback` processing with authorization code exchange

- **What is the impact?**
  - Complete authentication system failure - users cannot access protected resources
  - All protected API endpoints inaccessible despite successful Keycloak login
  - Sprint 2 test suite fails on authentication scenarios
  - Frontend accessible but authentication flow broken

- **Root Cause Analysis (5 Whys):**
  - **Why 1:** Why does OAuth2 callback return 500? → OAuth2-proxy token verification failing
  - **Why 2:** Why is token verification failing? → ID token issuer URL mismatch
  - **Why 3:** Why do issuer URLs mismatch? → OAuth2-proxy expects `:80` port, Keycloak issues without port
  - **Why 4:** Why does Keycloak issue tokens without port? → Keycloak on default HTTP port 80 omits port in issuer claim
  - **Why 5:** Why was OAuth2-proxy configured with explicit port? → EC2 environment configuration assumed explicit port needed like local environment

- **Key Assumptions Questioned:**
  - ✅ Verified: Frontend accessible via NGINX gateway (ISSUE-008 resolved)
  - ✅ Verified: OAuth2 flow starts correctly (redirects to Keycloak)
  - ✅ Verified: Keycloak authentication succeeds (accepts credentials)
  - ❌ **FAILED**: OAuth2-proxy issuer URL configuration matches Keycloak token issuer
  - ✅ Verified: Callback URL routing working (reaches OAuth2-proxy)

- **Desired Outcome:**
  - Complete OAuth2 authentication flow working end-to-end
  - Users can login and access protected resources
  - Test Cases 3B and 3C pass consistently
  - Authentication session cookies properly established and validated

---

## 2. Problem Breakdown
*This section breaks the complex issue into smaller, manageable sub-problems.*

- **Sub-problem 1: OAuth2 Token Verification**
  - OAuth2-proxy configured with explicit port in issuer URL (:80)
  - Keycloak issuing tokens with issuer claim without port (default HTTP)
  - OIDC specification requires exact issuer URL matching

- **Sub-problem 2: Environment Configuration Consistency**
  - Local environment behavior vs EC2 environment behavior differences
  - Port explicit specification requirements vary by environment
  - Configuration drift between environments

- **Sub-problem 3: Keycloak URL Generation Behavior**
  - Keycloak on port 80 (default HTTP) generates URLs without explicit port
  - OAuth2-proxy expects exact match of configured issuer URL
  - Default port behavior not accounted for in configuration

- **System Interactions:**
  - User → Keycloak (login) → OAuth2-proxy (callback) ❌ Verification failure
  - OAuth2-proxy issuer check: Expected `http://18.191.64.107:80/realms/...` vs Got `http://18.191.64.107/realms/...`

---

## 3. Solution Exploration
*A brainstorming phase to generate potential solutions without initial judgment.*

- **Option A: Remove Explicit Port from OAuth2-proxy Configuration**
  - Update ec2.env OAUTH2_PROXY_OIDC_ISSUER_URL and OAUTH2_PROXY_LOGIN_URL to remove :80 port
  - **Pros:** Matches Keycloak token issuer exactly, simple config change, aligns with HTTP default port behavior
  - **Cons:** May require restart of OAuth2-proxy service

- **Option B: Force Keycloak to Include Port in Issuer Claims**
  - Modify Keycloak configuration to explicitly include port 80 in token issuer
  - **Pros:** OAuth2-proxy config remains unchanged, explicit port clarity
  - **Cons:** Complex Keycloak configuration change, non-standard behavior

- **Option C: Use Non-Default Port for Keycloak**
  - Change Keycloak to use port 8080 externally and update all configurations
  - **Pros:** Explicit port usage, clear configuration
  - **Cons:** Major configuration change, affects frontend and other components

---

## 4. Implementation and Testing
*A log of the iterative, scientific process of testing hypotheses and implementing fixes. Each iteration is a single experiment.*

### Iteration 1: Log Analysis and Root Cause Identification
- **Action:** Examine OAuth2-proxy logs for specific error messages during callback processing
- **Rationale:** Get detailed error information to identify exact failure point in OAuth2 flow
- **Result:** ROOT CAUSE IDENTIFIED - OAuth2-proxy logs show exact issuer URL mismatch error
- **Notes:** Error message: `expected "http://18.191.64.107:80/realms/keystone-mvp" got "http://18.191.64.107/realms/keystone-mvp"`

### Iteration 2: OAuth2-proxy Configuration Fix
- **Action:** Update ec2.env to remove explicit :80 port from OAUTH2_PROXY_OIDC_ISSUER_URL and OAUTH2_PROXY_LOGIN_URL
- **Rationale:** Align OAuth2-proxy configuration with actual Keycloak token issuer format
- **Result:** SUCCESS - OAuth2 authentication flow now working end-to-end
- **Notes:** Immediate resolution after OAuth2-proxy restart. Users can now complete authentication and access protected resources.

---

## 5. Final Solution & Review
*This section documents the final, successful solution and captures the key learnings.*

- **Final Solution Implemented:**
  **Root Cause:** OAuth2-proxy configured with explicit port (:80) in issuer URL while Keycloak issues tokens with issuer claim without port (standard HTTP default port behavior).

  **Solution Steps:**
  1. **Update OAuth2-proxy Configuration:**
     - File: `authentication/ec2.env`
     - Change: `OAUTH2_PROXY_OIDC_ISSUER_URL=http://18.191.64.107:80/realms/keystone-mvp`
     - To: `OAUTH2_PROXY_OIDC_ISSUER_URL=http://18.191.64.107/realms/keystone-mvp`
     - Change: `OAUTH2_PROXY_LOGIN_URL=http://18.191.64.107:80/realms/keystone-mvp/protocol/openid-connect/auth`
     - To: `OAUTH2_PROXY_LOGIN_URL=http://18.191.64.107/realms/keystone-mvp/protocol/openid-connect/auth`
  
  2. **Restart OAuth2-proxy Service:**
     - Command: `docker-compose restart oauth2-proxy`
     - Verify: OAuth2 authentication flow completes successfully
  
  3. **Test Complete Authentication Flow:**
     - Login via frontend ✅
     - OAuth2 callback processing ✅
     - Protected resource access ✅

  **Technical Details:**
  - Keycloak on default HTTP port 80 follows standard behavior of omitting port in URLs
  - OAuth2-proxy OIDC verification requires exact issuer URL matching
  - Default port behavior (80 for HTTP) means port should be omitted, not explicit

- **Key Takeaways:**
  1. **Default Port Behavior:** HTTP port 80 and HTTPS port 443 are typically omitted from URLs and token issuer claims
  2. **OIDC Issuer Validation:** OAuth2-proxy requires exact string matching between configured issuer and token issuer claim
  3. **Environment Configuration Nuances:** Different environments may have different port explicit requirements
  4. **Log Analysis Priority:** OAuth2-proxy logs provide detailed error messages for token verification failures
  5. **Configuration Consistency:** Issuer URL configuration must match exactly how the OIDC provider generates tokens

- **Preventative Actions:**
  1. **Default Port Documentation:** Document when to use explicit ports vs default port behavior in environment configurations
  2. **OIDC Configuration Validation:** Add validation scripts that verify OAuth2-proxy and Keycloak issuer URL consistency
  3. **Environment Configuration Testing:** Include OAuth2 flow testing in environment setup validation
  4. **Log Monitoring:** Set up monitoring for OAuth2-proxy token verification errors
  5. **Configuration Templates:** Create clear templates showing port usage patterns for different scenarios
  6. **Keycloak URL Inspection:** Add tools to inspect how Keycloak generates issuer claims in different port configurations

- **Relationship to Previous Issues:**
  - **ISSUE-008:** Resolved frontend accessibility, enabling authentication flow testing
  - **ISSUE-007:** Local environment authentication fixes provided pattern for OAuth2 troubleshooting
  - This issue represents the final piece for complete EC2 authentication functionality

- **Impact Assessment:**
  - **Pre-fix:** Complete authentication system failure in EC2
  - **Post-fix:** Full OAuth2 flow functional, protected resources accessible
  - **Test Results:** Expected improvement in Sprint 2 test suite authentication scenarios
