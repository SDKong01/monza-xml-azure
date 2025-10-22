## Sprint Goal

The primary goal for this sprint is to deploy the foundational public-facing services for our new simplified App Runner architecture. This involves establishing our central, public authentication service and successfully deploying the first version of the SENNA application onto App Runner with its custom domain.

### Scope

**In Scope for Sprint 3:**

- Provisioning the public-facing ALB and DNS for the central Keycloak authentication service (`auth.dev.kainam.app`).
    
- Deploying the SENNA application as an AWS App Runner service via Terraform.
    
- Initiating and validating the custom domain association for SENNA (`senna.dev.kainam.app`).
    
- Injecting the necessary OIDC environment variables into the SENNA App Runner service.
    
- Configuring Keycloak by creating the public OIDC clients for both SENNA and KIMBALL with the correct redirect URIs.
    

**Out of Scope for Sprint 3:**

- The backend API refactor for KIMBALL (`[KEY-10]`).
    
- Building the full CI/CD pipeline for SENNA (`[KEY-23]`).
    
- Implementation of the user-facing RBAC flow, password reset, or other user management features.
    
- Final production hardening tasks (CloudWatch alarms, S3 backups).
    

### Key Tasks

- **[KEY-26] Deploy & Expose Central Auth Service:** Provision the public-facing ALB, configure listeners, attach the certificate, and create the `auth.dev.kainam.app` DNS record.
    
- **[KEY-27] Deploy SENNA Service on App Runner:** Create the `aws_apprunner_service` Terraform resource, initiate the custom domain association, add the DNS validation records, and inject the required environment variables.
    
- **[KEY-28] Configure Keycloak for Public Clients:** Create the `senna-frontend` and `kimball-frontend` OIDC clients in Keycloak and set their valid redirect URIs.
    

### Success Criteria

By the end of the sprint on September 3rd, the following must be true and demonstrable:

1. The central authentication service is successfully deployed and publicly accessible via its secure DNS name (`https://auth.dev.kainam.app`).
    
2. The SENNA application is deployed on AWS App Runner, and the process to link its custom domain (`senna.dev.kainam.app`) has been successfully initiated and validated.
    
3. The Keycloak realm has been correctly configured with new public clients for both SENNA and KIMBALL, ready for them to integrate.