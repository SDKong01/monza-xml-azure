# ISSUE LOG: 003: OAuth2 Token Validation Failure - Issuer Mismatch

- **Date Opened:** August 2025
- **Owner:** DevOps Engineer
- **Status:** Resolved
- **Severity:** High

---

## 1. Problem Understanding
- **What is the problem?**
  - `oauth2-proxy` is returning a 500 Internal Server Error during the authentication callback, preventing login completion.
- **What is the impact?**
  - All users are blocked from logging in.
- **Root Cause Analysis (5 Whys):**
  - 1. Why the 500 error? -> `oauth2-proxy` was rejecting the ID token from Keycloak as invalid.
  - 2. Why was the token invalid? -> The issuer URL in the token (`http://18.191.64.107/...`) did not exactly match the issuer URL `oauth2-proxy` was configured to expect (`http://18.191.64.107:80/...`).
  - 3. Why the mismatch? -> Keycloak automatically omits the default port 80 from its issuer URL, but the configuration for `oauth2-proxy` included it explicitly.
  - 4. Why did the configuration include the port? -> An assumption was made during initial setup.
- **Desired Outcome:**
  - The issuer URL expected by `oauth2-proxy` exactly matches the one in the tokens issued by Keycloak, allowing validation to succeed.

---

## 4. Implementation and Testing
### Iteration 1: Update .env Configuration
- **Action:** Updated the `.env` file to remove the explicit port `:80` from the `OAUTH2_PROXY_OIDC_ISSUER_URL` variable.
- **Rationale:** To align the expected issuer with the actual issuer.
- **Result:** SUCCESS. Token validation succeeded, and the authentication flow completed.

---

## 5. Final Solution & Review
- **Final Solution Implemented:**
  - The `OAUTH2_PROXY_OIDC_ISSUER_URL` environment variable was corrected to remove the explicit default port 80.
- **Key Takeaways:**
  - OIDC token validation is case- and port-sensitive; issuer URLs must match exactly.
  - Default ports (80 for http, 443 for https) are often omitted by identity providers.
