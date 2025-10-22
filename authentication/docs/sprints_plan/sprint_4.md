# [SPRINT PLAN] :: Sprint 4 - Keycloak Deployment & SENNA Integration

**Target Date:** 2025-09-12
**Owner:** Project Manager

## 1. The Sprint Goal
A single, clear, and measurable sentence that defines success for this iteration.
> A SENNA user can successfully log in using the newly deployed Keycloak authentication service and access a protected backend resource, validating the end-to-end integration.

## 2. Scope
### In Scope:
- Provision a dedicated PostgreSQL RDS instance for the Keycloak service (KEY-31).
- Deploy and configure the Keycloak service on an EC2 instance (KEY-26).
- Finalize the ALB configuration to bring the `auth-dev.kainam.app` endpoint online (KEY-26-AUTH-ALB).
- Configure the Keycloak realm, roles, and OIDC clients for the SENNA application (KEY-28).
- Refactor the SENNA backend to remove legacy authentication and implement JWT validation middleware.
- Refactor the SENNA frontend to integrate a standard OIDC library for the full login/logout user lifecycle.
- Implement the CI/CD pipeline for developer preview environments.

### Out of Scope:
- Implementing a private backend endpoint via a bastion host (KEY-29-BASTION-HOST).
- Creating a secure VPC Peering connection to MongoDB Atlas (KEY-30-MONGO-INTEGRATION is deferred to Sprint 6).
- Implementing AWS WAF for ingress protection.
- User self-service features like "Forgot Password" or profile management.
- Social login providers (e.g., Google, GitHub).

## 3. Key Tasks
A high-level overview of the work to be done. For full details, see the `tasks.yml` file.
- **Phase 1:** Deploy the Keycloak Authentication Platform (RDS, EC2, ALB).
- **Phase 2:** Configure Keycloak Realm and Clients.
- **Phase 3:** Refactor SENNA Backend and Frontend for Integration.
- **Phase 4:** Implement Developer Preview Environments.

## 4. Success Criteria
How the Orchestrator will validate the completion of the sprint goal.
- The `auth-dev.kainam.app` endpoint is live, healthy, and serves the Keycloak login page.
- The SENNA frontend successfully redirects unauthenticated users to the Keycloak service.
- After a successful login, the SENNA backend correctly validates the JWT from Keycloak and grants access to a protected API route.
- The developer preview environment pipeline successfully creates and destroys a temporary environment for a test pull request.
- All acceptance criteria for tasks tagged for this sprint in `tasks.yml` are met.