# Keystone RBAC - Revised Engineering Execution Plan

This document provides a granular, step-by-step guide for the engineering team to execute the Keystone RBAC project, reflecting the updated plan as of Sprint 2.

---

## [KEY-EPIC-1] The Walking Skeleton (Sprint 1) - COMPLETE

**Goal:** A functional, end-to-end, but non-robust, login flow on a single EC2 instance.
**Status:** Successfully delivered.

---

## [KEY-EPIC-2] Foundational Robustness & IaC (Sprint 2)

**Goal:** Transform the "Walking Skeleton" into a secure, production-grade foundation using Infrastructure as Code.

* **WBS: [KEY-7] Define the core network in Terraform**
    * **Sub-task: Create reusable Terraform module for VPC & Subnets.**
        * Initialize a new Git repository for Terraform (`keystone-infrastructure`).
        * Create a module that defines a VPC with public and private subnets across two Availability Zones.
    * **Sub-task: Create reusable Terraform module for Gateways (Internet & NAT).**
        * Within the VPC module, add resources for an Internet Gateway (for public subnets) and a NAT Gateway with an Elastic IP (for private subnets).
    * **Sub-task: Create reusable Terraform module for layered Security Groups (`alb-sg`, `web-sg`, `db-sg`).**
        * Create a separate module for security groups that defines `alb-sg` (allows public port 443), `web-sg` (allows traffic from `alb-sg`), and `db-sg` (allows traffic from `web-sg`).
    * **Test:** Apply the Terraform configuration and verify in the AWS console that the VPC, subnets, gateways, and security groups have been created correctly.

* **WBS: [KEY-8] Implement secure secrets management**
    * **Sub-task: Create Terraform module to provision secrets in AWS Secrets Manager.**
        * Write a Terraform module to create placeholder secrets for `DATABASE_USER`, `DATABASE_PASSWORD`, `KEYCLOAK_ADMIN_USER`, and `KEYCLOAK_ADMIN_PASSWORD`.
    * **Sub-task: Define EC2 IAM Role with scoped permissions in Terraform.**
        * Define an IAM Role for the EC2 instance with a policy that grants read-only access *only* to the specific secrets created above.
    * **Sub-task: Develop EC2 `user_data` script for fetching and injecting secrets at container startup.**
        * Write a shell script that will be used as `user_data` for the EC2 instance. The script will use the AWS CLI to fetch secrets and export them as environment variables before running `docker-compose up`.
    * **Test:** Manually run the script on a test instance to verify it correctly fetches and exports the secrets.

* **WBS: [KEY-9] Configure NGINX Gateway for Production**
    * **Sub-task: Create `nginx.conf` template compatible with Terraform's `templatefile` function.**
        * Create an `nginx.conf.tftpl` file. This template will include variables for upstream service names (e.g., `${backend_host}`).
    * **Sub-task: Implement `auth_request` and reverse proxy rules in the template.**
        * Configure `location` blocks to proxy to frontend and backend services. The backend location block must include the `auth_request` directive pointing to the `oauth2-proxy` service.
    * **Sub-task: Create a `Dockerfile` to containerize the templated NGINX configuration.**
        * Create a simple `Dockerfile` that uses the official NGINX image as a base and copies the rendered `nginx.conf` file into the correct directory.
    * **Test:** Build the NGINX container locally and test that it correctly routes traffic and protects the backend endpoint.

---

## [KEY-EPIC-3] Backend API Refactor (Sprint 3)

**Goal:** Decommission all legacy authentication logic from the backend service.

* **WBS: [KEY-10] Refactor backend API to use gateway authentication**
    * **Sub-task: Create reusable FastAPI dependency:**
        * Create a new Python function that acts as a FastAPI dependency to read and require the presence of `X-User-Email` and `X-User-Roles` headers.
    * **Sub-task: Refactor all protected endpoints:**
        * Systematically replace old JWT validation logic in every protected API endpoint with the new header-based dependency.
    * **Sub-task: Decommission legacy /login endpoint:**
        * Delete the entire `/login` endpoint and all related password-hashing and JWT-creation code.
    * **Sub-task: Remove password fields from application database:**
        * Create and apply a database migration t o drop the password hash column from the legacy user table.
    * **Test:** Run a full suite of integration tests to ensure all protected endpoints work correctly with the new dependency and fail appropriately without the required headers.

* **WBS: [KEY-11] Continue IaC: Codify Application Services**
    * Create a new Terraform module for the Application Load Balancer (ALB), configuring it for HTTPS.
    * Create a Terraform module for the EC2 instance (as an Auto Scaling Group with a Launch Template) that uses the `user_data` script from Sprint 2.
    * Create a Terraform module for the RDS PostgreSQL instance.
    * Apply the Terraform configuration to provision these resources and replace the manually-created components from Sprint 1.
    * **Test:** Verify that the fully-codified environment is running and that the application is accessible and functional through the ALB.

---

## [KEY-EPIC-4] Business Logic & User Management (Sprint 4)

**Goal:** Implement the core RBAC features and user management flows.

* **WBS: [KEY-12] Implement Role-Based Access Control (RBAC)**
    * This task remains the same as the previous plan: configure roles in Keycloak, enforce them in the backend by checking the `X-User-Roles` header, and conditionally render UI components in the frontend.

* **WBS: [KEY-13] Implement Self-Serve Password Reset**
    * This task remains the same: configure SMTP settings in Keycloak and enable the "Forgot password" feature.

* **WBS: [KEY-14] Implement Admin API for Role Management**
    * This task remains the same: create a service account client in Keycloak and build a backend endpoint that uses the Keycloak Admin API to manage user roles.

---

## [KEY-EPIC-5] Operational Readiness & Migration (Sprint 5)

**Goal:** Finalize production hardening and execute the user migration.

* **WBS: [KEY-15] Configure CloudWatch Logging & Alarms**
    * This task remains the same as the previous plan.

* **WBS: [KEY-16] Implement S3 Backup Script for Keycloak Realm**
    * This task remains the same as the previous plan.

* **WBS: [KEY-17] Develop and Execute Internal User Migration**
    * This task remains the same as the previous plan.

---

## [KEY-EPIC-6] Go-Live & Documentation (Sprint 6)

**Goal:** Launch to production and complete all necessary documentation.

* **WBS: [KEY-18] Create Developer & On-Call Documentation**
    * This task remains the same as the previous plan.

* **WBS: [KEY-19] Execute Production Go-Live Checklist**
    * This is a new placeholder task for the final deployment activities.