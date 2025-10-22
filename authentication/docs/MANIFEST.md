# [PROJECT MANIFEST] :: Keystone RBAC

**Last Updated:** 2025-09-24 12:04 CST

## 1. Project Vision
To replace a legacy authentication system with a robust, centralized RBAC solution using Keycloak, deployed on AWS via Infrastructure as Code.

## 2. Current Sprint Goal
**Sprint 5 - Kainam Platform Integration Pilot:** The goal of this sprint is to pivot from the SENNA application and perform the first-ever integration of our new Keycloak authentication service with the **Kainam Platform skeleton**.

The primary deliverable is a successful end-to-end demonstration of a user logging into the Kainam Platform via Keycloak. This involves:

-   **A Configured Keycloak:** The `kainam-dev` realm will be updated with new OIDC clients specifically for the Kainam Platform.
-   **An Integrated Backend:** The Kainam Platform's backend API will be secured, capable of validating JWTs issued by Keycloak.
-   **An Integrated Frontend:** The Kainam Platform's frontend will have a functional user login and logout flow managed by a standard OIDC library.

## 3. Project Status

### Architecture & Service Status

**Architectural State: ✅ PIVOT COMPLETE**
- The project has officially pivoted from a central NGINX gateway model to a simplified architecture using **AWS App Runner** with public endpoints and custom domains.

**New Public Services (Sprint 5):**
- **Central Auth Service**: `https://auth-dev.kainam.app` ✅ **OPERATIONAL**
- **SENNA Application**: `https://senna-dev.kainam.app` ✅ **DEPLOYED (Integration Postponed)**
- **Kainam Platform Frontend**: `https://console-dev.kainam.app` ✅ **DEPLOYED & OPERATIONAL**

**CI/CD Infrastructure Status (KEY-35-KAINAM-CICD):**
- **Task Status**: ✅ **PARTIALLY COMPLETE** - Frontend pipeline operational, backend pending
- **Frontend CI/CD**: ✅ **OPERATIONAL** - Docker image builds and ECR deployments working
- **Backend CI/CD**: ⏳ **INFRASTRUCTURE READY** - Pipeline created, awaiting Dockerfile creation
- **Infrastructure**: ✅ **DEPLOYED** - 4 new CodePipeline resources (2 build projects + 2 pipelines)

**App Runner Infrastructure Status (KEY-33-KAINAM-INFRA):**
- **Task Status**: ✅ **PARTIALLY COMPLETE** - Frontend App Runner deployed, backend pending
- **Frontend Service**: ✅ **RUNNING** - `kainam-platform-front-dev` with custom domain
- **Backend Service**: ⏳ **PENDING** - App Runner deployment awaiting backend CI/CD completion
- **Custom Domain**: ✅ **ACTIVE** - SSL certificate validated and DNS configured
- **Infrastructure**: ✅ **DEPLOYED** - 2 new App Runner resources + Route 53 CNAME record

**Authentication Configuration Status (KEY-32-KAINAM-CLIENT-CONFIG):**
- **Task Status**: ✅ **PARTIALLY COMPLETE** - Frontend OIDC client configured, backend client postponed
- **Frontend Client**: ✅ **CONFIGURED** - `kainam-frontend` public client in `kainam-dev` realm
- **Backend Client**: ⏳ **POSTPONED** - Confidential client creation deferred pending backend deployment
- **Integration Ready**: ✅ **FOUNDATION** - Authentication infrastructure ready for frontend development
- **Development Scope**: 🔄 **PENDING** - OIDC library integration and UI implementation required

## 4. Key Artifacts
| Artifact                | Path                                | Status          |
| ----------------------- | ----------------------------------- | --------------- |
| Task Breakdown          | [`/docs/tasks.yml`](#)              | `🔄 Needs Update` |
| Technical Debt Report   | [`/docs/tech_debt_report.md`](#)    | `🔄 In Progress`  |
| Sprint 4 Plan           | [`/sprint_plans/sprint_4.md`](#)    | `Archived`      |
| Sprint 5 Plan           | [`/sprint_plans/sprint_5.md`](#)    | `✅ Active`       |


## 5. Active Issues

| Issue ID | Title | Status | Severity | Owner |
| -------- | ----- | ------ | -------- | ----- |
<<<<<<< HEAD
=======
| [ISSUE-014](docs/issues/ISSUE-014-senna-ssl-certificate-invalid.md) | SENNA SSL Certificate Invalid (ERR_CERT_COMMON_NAME_INVALID) | Waiting for DNS validation from AWS | High | DevOps |
>>>>>>> 4eac6af (feat(keycloak): complete realm configuration and SENNA client setup)

## 6. Recently Resolved Issues

<<<<<<< HEAD
| Issue ID | Title | Resolution Date |
| -------- | ----- | --------------- |
| [ISSUE-014](...) | SENNA SSL Certificate Invalid | 2025-09-14 |
| [ISSUE-013](...) | Keycloak Console "somethingWentWrong" Error | 2025-09-09 |
| [ISSUE-012](...) | ALB Target Group Health Check Timeout | 2025-09-09 |
| [ISSUE-011](...) | Keycloak Bootstrap Script Deployment Failure | 2025-09-08 |


## 7. Conductor's Next Action

**Unblock the backend deployment by creating the application's `Dockerfile`**. This is the highest priority task and the critical path for the entire sprint.
=======
## 7. Conductor's Next Action