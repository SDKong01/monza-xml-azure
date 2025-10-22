# Keystone RBAC - Engineering Execution Plan

This document provides a granular, step-by-step guide for the engineering team to execute the Keystone RBAC project. Follow these instructions sequentially to build the "Walking Skeleton" and progressively enhance it with production-grade features.

---

## [KEY-EPIC-1] The Walking Skeleton (Sprint 1)

**Goal:** A functional, end-to-end, but non-robust, login flow on a single EC2 instance.

* **WBS: [KEY-1] Provision a Basic EC2 Instance**
    * Log into the AWS Management Console.
    * Navigate to the EC2 service dashboard.
    * Initiate the "Launch Instance" wizard.
    * Select an Amazon Machine Image (AMI), specifically "Amazon Linux 2" or a similar stable Linux distribution.
    * Choose the instance type `t3.medium`.
    * Proceed to network settings.
    * Create a new security group named `keystone-mvp-sg`.
    * Add an inbound rule to allow SSH traffic (port 22) exclusively from your development machine's IP address.
    * Add a second inbound rule to allow HTTP traffic (port 80) from all sources (`0.0.0.0/0`) for initial testing purposes.
    * Launch the instance using a pre-existing or new key pair.
    * **Test:** Verify you can successfully connect to the instance via SSH using the key pair.

* **WBS: [KEY-2] Create Initial Docker Compose File**
    * SSH into the newly provisioned EC2 instance.
    * Install Docker and Docker Compose.
    * Create a new project directory named `keystone`.
    * Inside the `keystone` directory, create a file named `docker-compose.yml`.
    * Define a top-level network named `keystone-net` for inter-container communication.
    * Define a service named `db` using the official `postgres:16.4` image. Assign it to the `keystone-net` network. Configure environment variables for a default user, password, and database name.
    * Define a service named `keycloak` using the official `quay.io/keycloak/keycloak:26.3.2` image. Assign it to the `keystone-net` network. Configure environment variables for the Keycloak admin user/password and the database connection details, pointing to the `db` service. Map port `8080` of the container to port `80` of the host EC2 instance.
    * Define a placeholder service for the `backend`. Assign it to the `keystone-net` network.
    * Define a placeholder service for the `frontend`. Assign it to the `keystone-net` network.
    * **Test:** Run `docker-compose up -d`. Verify that all containers start without errors by running `docker-compose ps`.

* **WBS: [KEY-3] Configure Minimal Keycloak Container**
    * Access the Keycloak admin console in your browser via the EC2 instance's public IP address.
    * Log in using the admin credentials defined in the `docker-compose.yml` file.
    * Create a new realm named `keystone-mvp`.
    * Within the `keystone-mvp` realm, navigate to the "Clients" section.
    * Create a new client with the Client ID `keystone-frontend`.
    * Configure the `keystone-frontend` client to be public, with the "Standard flow" enabled.
    * Set the "Valid Redirect URIs" to `*` for initial development.
    * Within the `keystone-mvp` realm, navigate to the "Users" section.
    * Create a new user with the email `testuser@keystone.com`.
    * Set a permanent password for this user in the "Credentials" tab.
    * **Test:** In an incognito browser window, navigate to the Keycloak account console for the `keystone-mvp` realm and verify you can log in as `testuser@keystone.com`.

* **WBS: [KEY-4 & KEY-6] Backend Service & Integration**
    * Develop a basic FastAPI application.
    * Create a single API endpoint: `GET /api/v1/me`.
    * This endpoint should be configured to expect user information (e.g., `X-User-Email`, `X-User-Name`) in the request headers. It should return these headers in a JSON response.
    * Update the `backend` service definition in `docker-compose.yml` to build and run this FastAPI application.
    * Define a new service in `docker-compose.yml` for `oauth2-proxy`.
    * Configure `oauth2-proxy` environment variables to connect to the Keycloak `keystone-mvp` realm and the `keystone-frontend` client.
    * Configure `oauth2-proxy` to forward authenticated requests to the `backend` service.
    * Configure `oauth2-proxy` to pass the `email` and `name` claims from the ID token as headers to the backend.
    * **Test (Isolated):** Use a tool like `curl` to make a request to the `oauth2-proxy` endpoint. You should be redirected to the Keycloak login page. After logging in, you should be able to hit the `/api/v1/me` endpoint and see your user claims.

* **WBS: [KEY-5 & KEY-6] Frontend App & Integration**
    * Develop a basic React application.
    * Add a single "Login" button to the main page.
    * Configure the "Login" button's `onClick` handler to redirect the user to the `oauth2-proxy` endpoint.
    * After successful login and redirection back to the frontend, the application should make a `fetch` request to the backend's `/api/v1/me` endpoint.
    * Display the user's name and email received from the API response on the screen.
    * Update the `frontend` service definition in `docker-compose.yml` to build and run this React application.
    * **Test (End-to-End):** Access the frontend application in your browser. Click the "Login" button. You should be redirected to Keycloak, log in, be redirected back to the app, and see "Welcome, testuser@keystone.com" (or similar) displayed on the page.

---

## [KEY-EPIC-2] Foundational Robustness (Sprint 2)

**Goal:** Harden the "Walking Skeleton" with secure networking and a managed database.

* **WBS: [KEY-7] Provision & Migrate to AWS RDS PostgreSQL**
    * Navigate to the RDS service in the AWS Console.
    * Provision a new PostgreSQL instance (e.g., `db.t4g.medium`).
    * Configure its security group to only allow inbound traffic on port 5432 from the `keystone-mvp-sg` security group.
    * Use a database tool to connect to the containerized `db` and export the Keycloak data.
    * Connect to the new RDS instance and import the Keycloak data.
    * Update the `keycloak` service in `docker-compose.yml` to point its database connection variables to the new RDS instance endpoint and credentials.
    * Remove the `db` service definition from the `docker-compose.yml` file.
    * **Test:** Restart the Docker Compose stack. Verify that Keycloak starts correctly and that you can still log in with the `testuser@keystone.com` account, confirming it's reading data from RDS.

* **WBS: [KEY-8] Implement Secure Networking with ALB & HTTPS**
    * Navigate to the EC2 Load Balancing section in the AWS Console.
    * Provision a new Application Load Balancer (ALB).
    * Navigate to AWS Certificate Manager (ACM) and provision a new public SSL/TLS certificate for your domain.
    * Configure the ALB with an HTTPS listener on port 443, using the newly created ACM certificate.
    * Configure the listener to forward traffic to a target group that contains the EC2 instance on port 80.
    * Update your domain's DNS records to point to the new ALB.
    * Update the `keystone-mvp-sg` to allow traffic from the ALB.
    * Update the Keycloak client's "Valid Redirect URIs" to use the new HTTPS domain.
    * **Test:** Access the application via its new `https://` domain. Verify the SSL certificate is valid and the entire login flow still works.

* **WBS: [KEY-9] Implement Secrets Management**
    * Navigate to AWS Secrets Manager.
    * Create a new secret to store the RDS database credentials.
    * Create a second secret to store the Keycloak admin credentials.
    * Create a new IAM Role that has permission to read these specific secrets.
    * Attach this IAM Role to the EC2 instance profile.
    * Modify the `docker-compose.yml` file or a startup script to fetch these secrets from Secrets Manager at runtime and pass them as environment variables to the containers, removing them from plain text.
    * **Test:** Restart the stack. Verify all services start and function correctly, proving they have successfully retrieved their credentials from Secrets Manager.

---

## [KEY-EPIC-3] Business Logic Implementation (Sprint 3 & 4)
**Goal:** Layer on valuable, user-facing features like RBAC and password reset.

* **WBS: [KEY-10 & KEY-11] Implement Role-Based Access Control (RBAC)**
    * **Keycloak Configuration:**
        * Log into the Keycloak Admin Console for the `keystone-mvp` realm.
        * Navigate to "Roles" and create a new realm role named `analyst`.
        * Navigate to "Users", select `testuser@keystone.com`, and assign the `analyst` role via the "Role Mappings" tab.
        * Navigate to "Clients" -> `keystone-frontend` -> "Client Scopes".
        * Add a new mapper to include user realm roles in the ID token. Name the token claim `roles`.
    * **Backend Enforcement:**
        * Update the `oauth2-proxy` configuration to pass the new `roles` claim as a request header (e.g., `X-User-Roles`).
        * Create a new protected backend endpoint, `GET /api/v1/analyst-data`.
        * This endpoint must inspect the `X-User-Roles` header. If it contains `analyst`, return data. Otherwise, return a 403 Forbidden status.
    * **Frontend Visibility:**
        * In the React application, after login, decode the ID token to extract the `roles` array.
        * Implement conditional logic to display an "Analyst Dashboard" component only if the `roles` array includes `analyst`.
    * **Test:** Log in as `testuser@keystone.com`; the Analyst Dashboard should be visible. Create a new user without the role; the dashboard should be hidden. Programmatically test the `/api/v1/analyst-data` endpoint to verify the 403 logic.

* **WBS: [KEY-12] Implement Self-Serve Password Reset**
    * Navigate to "Realm Settings" -> "Email" tab in the Keycloak Admin Console.
    * Configure the SMTP settings to connect to a valid email-sending service (e.g., AWS SES).
    * Navigate to the "Login" tab.
    * Ensure the "Forgot password" switch is enabled.
    * **Test:** Go to the application's login page. Click the "Forgot Password" link. Enter a user's email, follow the link in the received email, successfully reset the password, and log in with the new credentials.

* **WBS: [KEY-13] Implement Admin API for Role Management**
    * In Keycloak, create a new confidential client named `user-management-service`.
    * Enable the "Service Accounts Enabled" option.
    * In the "Service Account Roles" tab, assign the `manage-users` role from the `realm-management` client.
    * In the backend service, create a new endpoint, e.g., `POST /api/v1/users/{userId}/roles`.
    * This endpoint's logic will first perform a client credentials flow to get an access token for the `user-management-service`.
    * It will then use this token to make a call to the Keycloak Admin API to modify the roles for the specified `userId`.
    * **Test:** Use a tool like Postman to call your new endpoint and assign a role to a user. Verify in the Keycloak UI that the role mapping was successfully updated.

---

## [KEY-EPIC-4] Operational Readiness & Migration (Sprint 5 & 6)
**Goal:** Prepare the system for production operations and execute the final user migration.

* **WBS: [KEY-14] Configure CloudWatch Logging & Alarms**
    * Ensure the EC2 instance's IAM role has permissions to write to CloudWatch Logs.
    * Configure the Docker daemon on the EC2 instance to use the `awslogs` log driver.
    * Restart the Docker daemon and all application containers.
    * In the CloudWatch console, create an alarm based on the `CPUUtilization` metric for the EC2 instance, with a threshold like `> 80% for 5 minutes`.
    * Create a second alarm based on the `StatusCheckFailed` metric.
    * Configure both alarms to notify an SNS topic.
    * **Test:** Verify log groups are created and receiving streams from all containers. Test the alarm by temporarily lowering a threshold to trigger an SNS notification.

* **WBS: [KEY-15] Implement S3 Backup Script for Keycloak Realm**
    * Create a private S3 bucket to store backups.
    * Create an IAM policy that grants `s3:PutObject` access to that bucket and attach it to the EC2 instance's IAM role.
    * Write a shell script on the EC2 instance that:
        1.  Executes `docker exec` to run the Keycloak `kc.sh export` command, saving the realm data to a file.
        2.  Uses the AWS CLI to `cp` the exported file to the S3 bucket with a timestamped name.
        3.  Cleans up the local export file.
    * Configure a system cron job to run this script on a nightly schedule.
    * **Test:** Run the script manually and verify the export file appears in S3. Check cron logs to ensure the scheduled job executes successfully.

* **WBS: [KEY-16] Develop and Execute Internal User Migration**
    * **Develop Script:**
        * Write a script (e.g., in Python) that reads users from the legacy MongoDB database.
        * The script will use the Keycloak Admin API client (from KEY-13) to create each user in Keycloak.
        * The script must be idempotent (it should not create duplicate users if run multiple times).
        * It must map legacy roles to the new Keycloak roles.
        * It must set a temporary password and force the user to change it on their first login.
    * **Execute Migration:**
        * Perform a dry run of the script against the staging environment and validate the results.
        * During a planned maintenance window, run the script against the production Keycloak instance.
        * Monitor script logs and perform spot-checks on migrated accounts in the Keycloak UI.
    * **Test:** Have a small group of pilot users log in with their old credentials to confirm they are prompted to reset their password and can access the system successfully.

* **WBS: [KEY-17] Create Developer & On-Call Documentation**
    * **Developer Quick-Start Guide:**
        * Create a `QUICKSTART.md` file in the project repository.
        * Document the authentication flow, the role of `oauth2-proxy`, and the headers it injects (`X-User-Email`, `X-User-Roles`, etc.).
        * Provide clear instructions and code snippets for how a new backend service can read these headers to identify the user and their permissions.
    * **On-Call Runbook:**
        * Create a `RUNBOOK.md` file.
        * Document common failure scenarios (e.g., "Keycloak container is down," "Users cannot log in," "High CPU on EC2").
        * For each scenario, provide clear, step-by-step diagnostic and resolution procedures.
    * **Test:** Ask a developer from another team to follow the quick-start guide. Have a team member role-play an on-call incident using only the runbook to see if they can resolve it.