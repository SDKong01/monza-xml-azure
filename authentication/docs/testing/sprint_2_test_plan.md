# [SPRINT TEST PLAN] :: Sprint 2 - Foundational Robustness & IaC

**Date:** 2025-08-28
**Owner:** Architect & DevOps Engineer

## 1. Sprint Goal Alignment
This test plan supports the primary sprint goal as defined in the **Project Keystone Jira Plan**:
> *"Transform the 'Walking Skeleton' into a secure, production-grade foundation using Infrastructure as Code."*

## 2. Features Under Test
The following tasks from the Jira plan are the primary focus for testing in this sprint:
- `KEY-7`: Define the core network in Terraform (VPC, Subnets, Gateways, Security Groups).
- `KEY-8`: Implement secure secrets management (AWS Secrets Manager & IAM Roles).
- `KEY-9`: Configure NGINX Gateway for Production (with `auth_request`).

## 3. Component & Integration Test Scenarios
The following infrastructure and gateway scenarios will be executed manually using `curl` and the AWS CLI against the `dev` environment.

### Scenario 1: Verification of Secure Network Topology
- **Given** the Terraform scripts for the network have been successfully applied
- **When** a test EC2 instance is launched in a **private subnet**
- **Then** it should **NOT** be accessible from the public internet
- **And** it **SHOULD** be able to make outbound requests (e.g., `curl https://google.com`).
- **And** when a test is made from an EC2 instance in the `kainam-dev-web-sg` to the RDS instance in the `kainam-db-sg-dev` on port 5432
- **Then** the connection should be **successful**.
- **And** when a test is made from the public internet to the RDS instance
- **Then** the connection should **time out**.

### Scenario 2: Unauthorized Access to Protected API Gateway (auth_request Flow)
- **Given** a user who is **not** logged in
- **When** they attempt to directly access the `/api/v1/me` endpoint via the public NGINX gateway URL
- **Then** NGINX should trigger an internal `auth_request` call to oauth2-proxy at `/oauth2/auth`
- **And** oauth2-proxy should return **HTTP 401 Unauthorized** for the internal auth check
- **And** NGINX should convert this to an **HTTP 302 Found** redirect to `/oauth2/start?rd=/api/v1/me`
- **And** the request should **NOT** reach the backend service
- **And** oauth2-proxy logs should show the auth_request call: `GET - "/oauth2/auth" HTTP/1.0 [...] 401 13`
- **And** the user should **NOT** be able to access oauth2-proxy directly on port 4180 (connection refused)

### Scenario 3: Successful Authenticated API Access via Gateway (Header Injection)
- **Given** a user is logged in and has a valid `_oauth2_proxy` session cookie
- **When** they make a request to the `/api/v1/me` endpoint via the public NGINX gateway, providing their session cookie
- **Then** NGINX should trigger an internal `auth_request` call to oauth2-proxy at `/oauth2/auth`
- **And** oauth2-proxy should return **HTTP 200 OK** for the internal auth check with user identity headers
- **And** NGINX should capture the auth response headers: `X-Auth-Request-Email`, `X-Auth-Request-User`, `X-Auth-Request-Groups`
- **And** NGINX should forward the request to the backend with injected headers: `X-User-Email`, `X-User-Name`, `X-User-Roles`
- **And** the backend should return a **200 OK** status code with user data
- **And** backend logs should show the received headers: `X-User-Email: user@example.com`, `X-User-Name: username`
- **And** the complete flow should demonstrate: User → NGINX Gateway → auth_request validation → Backend (with headers)

## 4. Security & Configuration Testing
- **Target:** Secrets Management and Injection.
- **Goal:** Verify that no secrets are hardcoded and the injection mechanism works as designed.
- **Test Steps:**
    1. SSH into the running EC2 instance.
    2. Run `docker exec <nginx_container> env` and `docker exec <backend_container> env`.
    3. **Verify** that no sensitive credentials (e.g., database passwords) are present as plaintext environment variables.
    4. Check the application startup logs.
    5. **Verify** that the application successfully connects to the RDS database, proving it has retrieved the credentials correctly from Secrets Manager at runtime.

## 5. Exploratory Testing Charter
- **Mission:** Attempt to bypass the gateway's security controls.
- **Areas to Explore:**
    - Attempt to access the backend service's internal IP/port directly from another instance in the VPC that is *not* in the `web-sg`.
    - Send malformed or expired JWTs as cookies to the gateway to ensure they are rejected.
    - Test non-API routes (e.g., `/`) to ensure they are correctly proxied to the frontend service without requiring authentication.

## 6. Success Criteria for This Sprint
- All Component & Integration scenarios (Section 3) must pass in the `dev` environment.
- The Security & Configuration test (Section 4) must pass, confirming no secrets are exposed.
- No `Critical` or `High` severity security vulnerabilities related to the network or gateway configuration are identified.