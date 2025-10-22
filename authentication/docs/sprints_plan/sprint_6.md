# [SPRINT PLAN] :: Sprint 6 - Build & Harden

**Target Date:** 2025-10-01
**Owner:** Project Manager

## 1. The Sprint Goal
A single, clear, and measurable sentence that defines success for this iteration.
> To expand upon the "Walking Skeleton" by fully integrating authentication across the entire Kainam Platform, implementing foundational monitoring, and establishing a robust developer workflow.

## 2. Scope
### In Scope:
- Applying the JWT validation middleware to **all** necessary backend endpoints.
- Implementing "Protected Routes" across the **entire** frontend application to secure all user-facing pages.
- Creating basic roles (e.g., `user`, `admin`) in Keycloak and ensuring they appear in the user's JWT upon login.
- Implementing foundational monitoring and logging for the Keycloak and Kainam Platform services using AWS CloudWatch.
- Automating the creation of "Preview Environments" for each developer pull request to accelerate the development cycle.

### Out of Scope:
- Any advanced, fine-grained permissions logic within the applications (beyond checking for a role).
- The full refactor of the legacy SENNA application.
- Advanced user management features (e.g., inviting users, self-service profile updates).
- A formal penetration testing engagement.

## 3. Key Tasks
A high-level overview of the work to be done. For full details, see the `tasks.yml` file.
- **Phase 1 (Development):** Complete the full frontend and backend authentication integration by applying the established patterns across all required endpoints and pages.
- **Phase 2 (DevOps):** Implement the automated "Preview Environments" CI/CD pipeline.
- **Phase 3 (Operations):** Implement the foundational monitoring and logging solution in CloudWatch.
- **Phase 4 (Configuration):** Create and assign initial user roles (`user`, `admin`) in the Keycloak `dev` realm.

## 4. Success Criteria
How the Orchestrator will validate the completion of the sprint goal.
- All Kainam Platform API endpoints are protected and return a `401 Unauthorized` error if a valid JWT is not provided.
- All necessary pages in the frontend application are now "Protected Routes," correctly redirecting unauthenticated users to the login page.
- Opening a new Pull Request for the frontend or backend automatically deploys a temporary "Preview Environment" and posts its unique URL to the PR.
- Basic CloudWatch Dashboards are created, showing the health and request counts for the Keycloak and Kainam Platform services.
- A test user assigned an `admin` role in Keycloak has that role correctly appear in the `roles` claim of their decoded JWT.