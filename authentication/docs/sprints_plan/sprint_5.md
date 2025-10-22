# [SPRINT PLAN] :: Sprint 5 - Kainam Platform Auth Integration

**Target Date:** 2025-09-24
**Owner:** Project Manager

## 1. The Sprint Goal
A single, clear, and measurable sentence that defines success for this iteration.
> A user can successfully log in to the Kainam Platform skeleton application using the Keycloak authentication service, proving the end-to-end integration.

## 2. Scope
### In Scope:
- Create and configure the necessary Route 53 subdomain for the Kainam Platform.
- Create and configure new OIDC clients (`kainam-frontend`, `kainam-backend`) in the Keycloak `dev` realm.
- Implement JWT token validation middleware on the Kainam Platform's backend API.
- Integrate a standard OIDC library into the Kainam Platform's frontend to handle the complete user login and logout flow.

### Out of Scope:
- ALL previously planned tasks for the SENNA application (security hardening, performance tuning, launch).
- The production go-live of the SENNA application's new authentication system.
- Any features for the Kainam Platform beyond the basic user authentication cycle.
- User self-service features like "Forgot Password" or profile management.

## 3. Key Tasks
A high-level overview of the work to be done. For full details, see the `tasks.yml` file.
- **Phase 1 (Blockers):** Configure DevOps foundations (Route 53 subdomain, Keycloak OIDC clients).
- **Phase 2 (Development):** Integrate Kainam Backend API with Keycloak.
- **Phase 3 (Development):** Integrate Kainam Frontend application with Keycloak.
- **Phase 4 (Validation):** Perform end-to-end testing of the complete login/logout flow.

## 4. Success Criteria
How the Orchestrator will validate the completion of the sprint goal.
- The Kainam Platform is accessible and resolves correctly via its new public subdomain.
- The new OIDC clients for the Kainam Platform are active and correctly configured in Keycloak.
- The Kainam Platform frontend successfully redirects unauthenticated users to the Keycloak service.
- The Kainam Platform backend correctly validates a JWT from Keycloak and grants access to a protected API route.
- A test user can complete the full login and logout cycle on the Kainam Platform.