# [SPRINT PLAN] :: Sprint 2 - Foundational Robustness

**Target Date:** 2025-08-27
**Owner:** Project Manager

## 1. The Sprint Goal
To transform the "Walking Skeleton" from Sprint 1 into a secure, production-grade foundation by migrating all core infrastructure to Terraform and implementing secure secrets management.

## 2. Scope
### In Scope:
- [KEY-7] Define the core network in Terraform (VPC, Subnets, Gateways, SGs).
- [KEY-8] Implement secure secrets management with AWS Secrets Manager and IAM Roles.
- [KEY-9] Configure a production-ready, containerized NGINX gateway.

### Out of Scope:
- Refactoring the backend API logic (Scheduled for Sprint 3).
- Implementing business logic like RBAC (Scheduled for Sprint 4).

## 3. Key Tasks
- **Link to Detailed Tasks:** [`/tasks/keystone_tasks.yml`](#) (filter for `KEY-EPIC-2`).

## 4. Success Criteria
- All infrastructure defined in the scope is successfully provisioned via `terraform apply`.
- The EC2 instance can successfully fetch its secrets from AWS Secrets Manager at startup.
- The NGINX gateway container builds successfully and can be run locally.