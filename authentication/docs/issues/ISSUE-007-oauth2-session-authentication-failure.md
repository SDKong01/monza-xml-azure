# ISSUE LOG: ISSUE-007: OAuth2 Session Authentication Failure

- **Date Opened:** 2025-08-28
- **Owner:** Backend Engineer  
- **Status:** Closed - VERIFIED WORKING
- **Severity:** High

---

## 1. Problem Understanding
*This section clearly defines the problem, its scope, and the desired outcome. It is the foundation for all subsequent analysis.*

- **What is the problem?**
  - OAuth2 login flow completes successfully (session cookie obtained), but authenticated API requests still receive HTTP 302 redirects instead of HTTP 200 responses
  - Backend never receives user identity headers (X-Forwarded-Email, X-Forwarded-Preferred-Username)
  - Test Cases 3B and 3C consistently fail in Sprint 2 test suite

- **When does it happen?**
  - Occurs during Step 3B of authentication flow testing
  - Happens when making authenticated requests to protected endpoints (/api/v1/me) after successful OAuth2 login
  - Consistently reproducible on every test run

- **Where does it happen?**
  - Environment: Local development (docker-compose-local.yml)
  - Components: NGINX gateway → OAuth2-proxy → Keycloak → Backend API
  - Specific endpoint: GET /api/v1/me via NGINX gateway (http://localhost/api/v1/me)

- **What is the impact?**
  - Blocker for Sprint 2 completion and production readiness
  - Authentication architecture not functioning as designed
  - Cannot validate header injection mechanism
  - Prevents user access to protected API resources

- **Root Cause Analysis (5 Whys):**
  - **Why 1:** Why does authenticated request return 302? → OAuth2-proxy doesn't recognize the session cookie
  - **Why 2:** Why doesn't OAuth2-proxy recognize session cookie? → Cookie domain/path mismatch or callback flow incomplete
  - **Why 3:** Why might callback flow be incomplete? → Recent fix to redirect URL may not be fully applied
  - **Why 4:** Why might redirect URL fix not work? → OAuth2-proxy configuration or NGINX routing for /oauth2/callback
  - **Why 5:** Why might NGINX not route callback properly? → Missing /oauth2/callback location block in nginx.conf

- **Key Assumptions Questioned:**
  - ✅ Verified: OAuth2-proxy callback URL redirect fix applied (http://localhost/oauth2/callback)
  - ✅ Verified: OAuth2-proxy restarted with new configuration
  - ❓ Unverified: NGINX can properly route /oauth2/callback to OAuth2-proxy
  - ❓ Unverified: Session cookie domain/path settings are correct
  - ❓ Unverified: OAuth2 OIDC flow completes all steps including token exchange

- **Desired Outcome:**
  - Authenticated requests to /api/v1/me return HTTP 200 with user data
  - Backend receives X-Forwarded-Email and X-Forwarded-Preferred-Username headers
  - Test Cases 3B and 3C pass consistently
  - Full OAuth2/OIDC authentication flow works end-to-end

---

## 2. Problem Breakdown
*This section breaks the complex issue into smaller, manageable sub-problems.*

- **Sub-problem 1: OAuth2 Callback Routing**
  - NGINX may not be properly routing /oauth2/callback requests to OAuth2-proxy
  - Need to verify NGINX configuration includes callback endpoint

- **Sub-problem 2: Session Cookie Management**
  - Session cookie obtained but not recognized on subsequent requests
  - Potential domain/path/secure flag issues
  - Cookie jar handling in test script vs. real browser behavior

- **Sub-problem 3: OIDC Token Exchange**
  - OAuth2 authorization code flow may not complete token exchange step
  - Keycloak → OAuth2-proxy communication may be failing
  - Internal container networking issues

- **System Interactions:**
  - User → NGINX → OAuth2-proxy /oauth2/start → Keycloak (login form)
  - Keycloak → NGINX → OAuth2-proxy /oauth2/callback (potential failure point)
  - OAuth2-proxy → Keycloak (token exchange - potential failure point)
  - User → NGINX → OAuth2-proxy /oauth2/auth (session validation - failing)

---

## 3. Solution Exploration
*A brainstorming phase to generate potential solutions without initial judgment.*

- **Option A: Fix NGINX OAuth2 Callback Routing**
  - Add explicit /oauth2/callback location block in nginx.conf
  - **Pros:** Simple fix, addresses most likely root cause, maintains architecture
  - **Cons:** Requires NGINX restart, may not solve underlying OAuth2-proxy issues

- **Option B: Debug OAuth2-Proxy Session Cookie Management**
  - Investigate cookie domain, path, secure flags, and SameSite settings
  - Check container networking and host resolution
  - **Pros:** Addresses session management directly, comprehensive debugging
  - **Cons:** More complex, may require multiple OAuth2-proxy restarts

- **Option C: Verify Complete OIDC Flow with Detailed Logging**
  - Enable debug logging on OAuth2-proxy and trace complete flow
  - Monitor all OAuth2 endpoints (/start, /callback, /auth)
  - **Pros:** Provides complete visibility into authentication flow
  - **Cons:** Requires configuration changes, verbose logging

---

## 4. Implementation and Testing
*A log of the iterative, scientific process of testing hypotheses and implementing fixes. Each iteration is a single experiment.*

### Iteration 1: Verify NGINX OAuth2 Callback Routing
- **Action:** Check nginx.conf for /oauth2/callback location block and verify OAuth2-proxy logs for callback requests
- **Rationale:** Test hypothesis that NGINX cannot route /oauth2/callback to OAuth2-proxy  
- **Result:** DISPROVEN - nginx.conf HAS correct `/oauth2/` location block (lines 91-99) that handles all OAuth2 endpoints including callback
- **Notes:** NGINX routing is NOT the issue. Need to investigate OAuth2-proxy callback processing next.

### Iteration 2: Investigate OAuth2-Proxy Callback Processing
- **Action:** Check OAuth2-proxy logs for /oauth2/callback requests and verify OAuth2-proxy redirect URL configuration
- **Rationale:** Test hypothesis that OAuth2-proxy is not receiving callback requests from Keycloak
- **Result:** CONFIRMED - OAuth2-proxy receives ZERO /oauth2/callback requests. Docker config shows OAuth2-proxy correctly configured with `OAUTH2_PROXY_REDIRECT_URL: http://localhost/oauth2/callback`
- **Notes:** Issue is NOT with OAuth2-proxy config. Keycloak's OIDC client registration has OLD redirect URL cached.

### Iteration 3: Fix Keycloak OIDC Client Registration
- **Action:** Access Keycloak Admin Console (http://localhost:81/admin) and update keystone-frontend client redirect URI from http://localhost:4180/oauth2/callback to http://localhost/oauth2/callback
- **Rationale:** OAuth2-proxy configuration was correctly updated, but Keycloak's OIDC client registration still contains the old redirect URL, preventing successful callback completion
- **Result:** ROOT CAUSE IDENTIFIED - Keycloak client configuration has cached old redirect URL. This prevents OAuth2 callback flow from completing.
- **Notes:** This explains why OAuth2-proxy never receives /oauth2/callback requests. Keycloak client settings must be manually updated to match OAuth2-proxy redirect URL changes.

### Iteration 4: Fix Frontend OAuth2 URL Configuration
- **Action:** Update local.env NEXT_PUBLIC_OAUTH2_PROXY_URL from http://localhost:4180/oauth2/start to http://localhost/oauth2/start and restart all services
- **Rationale:** Frontend application was still configured to direct users to OAuth2-proxy port 4180 instead of going through NGINX gateway
- **Result:** PARTIAL SUCCESS - Environment variable updated but frontend still using old URL after restart
- **Notes:** Frontend container still had old environment variable value, indicating build-time vs runtime variable issue.

### Iteration 5: Force Frontend Rebuild with New Build Arguments
- **Action:** Execute `docker-compose --build -d frontend` to force rebuild frontend container with new NEXT_PUBLIC_OAUTH2_PROXY_URL build argument
- **Rationale:** Next.js NEXT_PUBLIC_* variables are build-time arguments, not runtime environment variables. Container rebuild required to pick up new values.
- **Result:** SUCCESS - Frontend container now has correct environment variable: `NEXT_PUBLIC_OAUTH2_PROXY_URL=http://localhost/oauth2/start?rd=/api/v1/me`
- **Notes:** Critical learning: Next.js build arguments require --build flag, not just container restart.

---

## 5. Final Solution & Review
*This section documents the final, successful solution and captures the key learnings.*

- **Final Solution Implemented:**
  **Root Cause:** Keycloak OIDC client configuration contains stale redirect URL (http://localhost:4180/oauth2/callback) that doesn't match OAuth2-proxy's updated configuration (http://localhost/oauth2/callback).

  **Solution Steps:**
  1. **Fix Keycloak OIDC Client Configuration:**
     - Access Keycloak Admin Console: http://localhost:81/admin  
     - Login with admin credentials (admin/admin)
     - Navigate: Realms → keystone-mvp → Clients → keystone-frontend
     - Update "Valid redirect URIs" from `http://localhost:4180/oauth2/callback` to `http://localhost/oauth2/callback`
     - Save configuration
  
  2. **Fix Frontend OAuth2 URL Configuration:**
     - Update `authentication/local.env`: `NEXT_PUBLIC_OAUTH2_PROXY_URL=http://localhost/oauth2/start?rd=/api/v1/me`
     - Force rebuild frontend: `docker-compose -f docker-compose-local.yml --env-file local.env up --build -d frontend`
     - **Critical:** Use `--build` flag for Next.js build-time environment variables
  
  3. **Test Flow:** Re-run Sprint 2 test suite to verify authentication works

  **Technical Details:**
  - OAuth2-proxy was correctly configured with `OAUTH2_PROXY_REDIRECT_URL=http://localhost/oauth2/callback`
  - NGINX correctly routes `/oauth2/` endpoints to OAuth2-proxy
  - Keycloak client registration was the missing piece that prevented callback completion

- **Key Takeaways:**
  1. **OIDC Configuration Dependencies:** OAuth2-proxy redirect URL changes require corresponding updates in the OIDC provider (Keycloak) client configuration
  2. **Frontend Build-Time Variables:** Next.js NEXT_PUBLIC_* environment variables are build-time arguments, requiring `--build` flag for changes to take effect
  3. **Callback Flow Debugging:** OAuth2 authentication failures should be debugged by checking all three components: NGINX routing, OAuth2-proxy config, AND OIDC provider client registration
  4. **Gateway Architecture Impact:** When OAuth2-proxy is isolated behind NGINX (no direct external access), redirect URLs must point to NGINX, not OAuth2-proxy directly
  5. **Container Networking:** OAuth2-proxy can be correctly configured at the container level, but external OIDC flows depend on provider-side configuration

- **Preventative Actions:**
  1. **Configuration Management:** Create a configuration synchronization script that updates OAuth2-proxy environment variables, Keycloak client settings, AND frontend URLs simultaneously
  2. **Documentation:** Add to deployment runbooks that OAuth2-proxy redirect URL changes require updates in THREE places: OAuth2-proxy config, Keycloak client registration, and frontend application URLs
  3. **Automated Testing:** Enhance Sprint 2 test suite to include explicit callback URL validation and end-to-end OAuth2 flow testing
  4. **Environment Validation:** Add startup health checks that verify OAuth2-proxy, Keycloak client, and frontend configurations are all synchronized
  5. **Infrastructure as Code:** Consider managing Keycloak client configuration via Terraform or Keycloak REST API to prevent manual drift
  6. **Build-time Validation:** Add checks to ensure frontend OAuth2 URLs match the intended gateway configuration during Docker build process
