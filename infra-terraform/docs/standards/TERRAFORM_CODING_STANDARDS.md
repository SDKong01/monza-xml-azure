# [TERRAFORM CODING STANDARDS]

**Version:** 1.0
**Owner:** Orchestrator

## 1. Core Philosophy
- **Infrastructure is Code:** Every single resource provisioned in the cloud must be defined as code. No manual "click-ops" changes are permitted.
- **Modularity & Reusability:** Infrastructure should be composed of small, reusable, and versioned modules. Avoid monolithic configurations to promote clarity and maintainability.
- **Immutability & Consistency:** Aim for immutable infrastructure. Ensure that deployments are consistent and reproducible across all environments by locking provider and module versions.
- **Security by Default:** Security is not an afterthought. It must be embedded into the IaC process from the beginning, following the principle of least privilege.

## 2. Structure & Formatting
- **Standard Formatting:** All Terraform files (`.tf`, `.tfvars`) MUST be formatted using `terraform fmt` before being committed.
- **File Organization:** A standard module or environment directory should be organized into logical files:
    - `main.tf`: Contains the primary resource definitions.
    - `variables.tf`: Contains all variable declarations.
    - `outputs.tf`: Contains all output definitions.
    - `versions.tf`: Contains provider and Terraform version requirements.
- **Resource Naming:** Use a consistent naming convention for all resources, typically `[project]-[environment]-[service]-[resource_type]`.
- **Tagging:** All resources that support it MUST be tagged with, at a minimum, `Project`, `Environment`, and `ManagedBy = "Terraform"`.

## 3. State Management & Environments
- **Remote Backend:** Terraform state MUST be stored in a remote backend (e.g., AWS S3). Local state files are forbidden for shared projects.
- **State Locking:** The remote backend MUST be configured to support state locking to prevent concurrent modifications.
- **State Encryption:** The remote backend MUST be configured to encrypt the state file at rest.
- **Environment Strategy:** The strategy for separating environments (e.g., dev, staging, prod) MUST be documented in the `ENVIRONMENT_STRATEGY.md` artifact.

## 4. Modularity
- **Promote Reusability:** Split logical groups of resources into reusable modules to avoid duplication.
- **Version Control:** All modules MUST be version-controlled in their own repositories or a shared monorepo. Follow semantic versioning (SemVer) for module releases.
- **Module Sources:** Always source modules using a version constraint to ensure stability (e.g., `source = "git::https://github.com/my-org/my-module.git?ref=v1.0.2"`).
- **Clear Interfaces:** Modules must have clearly defined inputs (variables) and outputs. All module variables and outputs MUST have a `description`.
- **Module Documentation:** Each module MUST have a `README.md` file that explains its purpose, inputs, outputs, and provides a usage example.

## 5. Variables & Secrets
- **Avoid Hardcoding:** Never hardcode values like ARNs, instance sizes, or CIDR blocks. Use variables for all configurable parameters.
- **Variable Validation:** Use `validation` blocks in variable definitions to enforce constraints and prevent invalid input.
- **Sensitive Data:** NEVER store sensitive information (passwords, API keys, certificates) in plaintext within Terraform files or state.
- **Secrets Management:** Sensitive data MUST be fetched from a dedicated secrets management service (e.g., AWS Secrets Manager, HashiCorp Vault) using a data source.

## 6. Security Practices
- **Least Privilege:** All IAM roles and policies created in Terraform MUST adhere to the principle of least privilege. Avoid using wildcard (`*`) permissions where possible.
- **Network Security:** Security group and network ACL rules MUST be as restrictive as possible. Avoid opening ports to `0.0.0.0/0` unless it is for a public-facing service and is explicitly intended.
- **Encryption:** Ensure encryption is enabled for all relevant resources (e.g., S3 buckets, RDS instances, EBS volumes).

## 7. CI/CD & Testing
- **Automated Formatting & Validation:** The CI/CD pipeline MUST run `terraform fmt -check` and `terraform validate` on every commit.
- **Linting:** The pipeline should integrate a linting tool like `tflint` to catch common errors and enforce best practices.
- **Automated Planning:** The pipeline MUST run `terraform plan` and post the output to the pull request to allow for peer review before any changes are applied.
- **Module Testing:** For reusable modules, use a testing framework like `terratest` to write automated unit and integration tests.