# ISSUE LOG: 002: Split-Horizon DNS & Redirect URI Mismatch

- **Date Opened:** August 2025
- **Owner:** DevOps Engineer
- **Status:** Resolved
- **Severity:** Critical

---

## 1. Problem Understanding
- **What is the problem?**
  - The authentication flow is failing. Users are redirected from the app to Keycloak, which then shows an `Invalid parameter: redirect_uri` error. In other instances, the browser shows a `DNS_PROBE_FINISHED_NXDOMAIN` error for the hostname `keycloak`.
- **What is the impact?**
  - This is a critical blocker. No user can log in to the application.
- **Root Cause Analysis (5 Whys):**
  - 1. Why is the login failing? -> Keycloak is receiving an invalid `redirect_uri`, or the browser is being sent an unresolvable URL.
  - 2. Why is the URL wrong? -> `oauth2-proxy` is generating URLs based on its internal container network perspective (`http://keycloak:8080`) and sending them to the user's browser, which only understands the external perspective (`http://localhost:8081`).
  - 3. Why is it generating the wrong URL? -> This is a classic "split-horizon DNS" problem in containerized development. The proxy is not configured to distinguish between the public-facing URL needed by the browser and the internal URL needed for container-to-container communication.
  - 4. Why didn't simple fixes work? -> Attempts to whitelist one URL or the other failed because both contexts (internal and external) must be valid simultaneously.
- **Desired Outcome:**
  - The user is seamlessly redirected to the correct `localhost` Keycloak URL, can log in, and is redirected back to the application successfully.

---

## 4. Implementation and Testing
### Iteration 1: Hard Reset to Force Re-Import
- **Action:** Performed a hard reset (`docker compose down`, `docker volume rm ...`, `docker compose up`) to ensure an updated `redirectUris` whitelist in `keycloak-realm-app-export.json` was loaded.
- **Rationale:** To eliminate the possibility that Keycloak was operating on a stale configuration.
- **Result:** FAILURE. The issue persisted, proving the root cause was in the `oauth2-proxy` URL generation, not the Keycloak whitelist.

### Iteration 2: "Split URL" Configuration
- **Action:** Implemented a "Split URL" configuration in `docker-compose.yml` for the `oauth2-proxy` service.
- **Rationale:** To explicitly define the URLs for both public (browser) and private (inter-container) communication paths.
- **Result:** SUCCESS. `oauth2-proxy` now correctly constructs the `localhost`-based URL for the browser, resolving the DNS and `redirect_uri` errors.

---

## 5. Final Solution & Review
- **Final Solution Implemented:**
  - The `oauth2-proxy` service was configured with a "Split URL" strategy, setting browser-facing URLs (e.g., `OAUTH2_PROXY_OIDC_ISSUER_URL`) to use `localhost:8081` and server-to-server URLs (e.g., `OAUTH2_PROXY_REDEEM_URL`) to use the internal service name `keycloak:8080`.
- **Key Takeaways:**
  - When using proxies for authentication in a containerized environment, it is critical to explicitly define URLs for both public and private communication paths.
