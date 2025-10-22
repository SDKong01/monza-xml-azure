# ISSUE LOG: 001: Invalid Keycloak Admin Credentials

- **Date Opened:** August 2025
- **Owner:** DevOps Engineer
- **Status:** Resolved
- **Severity:** Critical

---

## 1. Problem Understanding
- **What is the problem?**
  - The Keycloak admin console at `http://localhost:8081` is rejecting the bootstrap credentials (`admin`/`admin123`).
- **What is the impact?**
  - This is a critical blocker, as it prevents all realm and user management needed to configure the OIDC provider.
- **Root Cause Analysis (5 Whys):**
  - 1. Why are credentials invalid? → The `admin` user was never created.
  - 2. Why was the user not created? → The Keycloak bootstrap process was skipped on startup.
  - 3. Why was it skipped? -> It detected a partially initialized database from a previous failed run in the persistent Docker volume.
  - 4. Why did a hard reset of the volume not fix it? -> Because the root cause was not a corrupted state, but a fundamental configuration error.
  - 5. What was the configuration error? -> The `docker-compose.yml` was using the wrong environment variables (`KC_BOOTSTRAP_*`) instead of the correct ones required by the image (`KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD`).
- **Desired Outcome:**
  - The Orchestrator can successfully log in to the Keycloak admin console using the defined bootstrap credentials.

---

## 4. Implementation and Testing
### Iteration 1: "Hard Reset" Procedure
- **Action:** Executed `docker compose down`, `docker volume rm keystone-rbca_postgres_data`, and `docker compose up -d`.
- **Rationale:** To destroy any corrupted state in the persistent volume and force the bootstrap process to re-run.
- **Result:** FAILURE. Credentials were still invalid. A direct DB query confirmed the `USER_ENTITY` table was empty.

### Iteration 2: Correct Environment Variables
- **Action:** Corrected the environment variable names in `docker-compose.yml` to `KEYCLOAK_ADMIN` and `KEYCLOAK_ADMIN_PASSWORD` and performed a final "Hard Reset".
- **Rationale:** To align the configuration with the official Docker image documentation.
- **Result:** SUCCESS. The admin user was created correctly, and the credentials now work.

---

## 5. Final Solution & Review
- **Final Solution Implemented:**
  - The environment variables in `docker-compose.yml` for the Keycloak service were corrected to match the official image specification.
- **Key Takeaways:**
  - Always verify the exact environment variable names required by a specific Docker image version.
  - A "clean slate" (fresh database volume) is the most reliable way to debug bootstrap processes.
