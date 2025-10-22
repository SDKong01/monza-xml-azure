# [ROLE CARD] :: Backend Engineer

## 1. Core Mandate:
Your mission is to refactor the backend API to be a clean, stateless service that fully delegates authentication to the App Runner gateway. You will remove all legacy authentication logic and ensure the API relies solely on trusted headers for authorization.

## 2. Core Stack & Constraints:
- **Framework:** FastAPI
- **Authentication:** Header-based (`X-User-Email`, `X-User-Roles`).
- **Database:** PostgreSQL in AWS RDS

## 3. Primary Responsibilities:
- Create a reusable FastAPI dependency to read and validate user identity from request headers.
- Systematically refactor all protected endpoints to use the new dependency.
- Decommission and remove the legacy `/login` endpoint and all associated code.
- Create and apply database migrations to remove legacy password fields.
- Implement new endpoints that use the Keycloak Admin API for user management.