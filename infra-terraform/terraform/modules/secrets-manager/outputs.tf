output "database_secret_arn" {
  description = "ARN of the database secret"
  value       = aws_secretsmanager_secret.database.arn
}

output "database_secret_name" {
  description = "Name of the database secret"
  value       = aws_secretsmanager_secret.database.name
}

output "database_secret_id" {
  description = "ID of the database secret"
  value       = aws_secretsmanager_secret.database.id
}

output "keycloak_admin_secret_arn" {
  description = "ARN of the Keycloak admin secret"
  value       = aws_secretsmanager_secret.keycloak_admin.arn
}

output "keycloak_admin_secret_name" {
  description = "Name of the Keycloak admin secret"
  value       = aws_secretsmanager_secret.keycloak_admin.name
}

output "keycloak_admin_secret_id" {
  description = "ID of the Keycloak admin secret"
  value       = aws_secretsmanager_secret.keycloak_admin.id
}

output "backend_client_secret_arn" {
  description = "ARN of the SENNA backend client secret"
  value       = aws_secretsmanager_secret.backend_client_secret.arn
}

output "backend_client_secret_name" {
  description = "Name of the SENNA backend client secret"
  value       = aws_secretsmanager_secret.backend_client_secret.name
}

output "backend_client_secret_id" {
  description = "ID of the SENNA backend client secret"
  value       = aws_secretsmanager_secret.backend_client_secret.id
}

output "secret_arns" {
  description = "Map of all secret ARNs for easy reference"
  value = {
    database              = aws_secretsmanager_secret.database.arn
    keycloak_admin        = aws_secretsmanager_secret.keycloak_admin.arn
    backend_client_secret = aws_secretsmanager_secret.backend_client_secret.arn
  }
}

output "secret_names" {
  description = "Map of all secret names for easy reference"
  value = {
    database              = aws_secretsmanager_secret.database.name
    keycloak_admin        = aws_secretsmanager_secret.keycloak_admin.name
    backend_client_secret = aws_secretsmanager_secret.backend_client_secret.name
  }
}

output "secrets_summary" {
  description = "Summary of all created secrets"
  value = {
    count = 3
    secrets = {
      database = {
        name        = aws_secretsmanager_secret.database.name
        arn         = aws_secretsmanager_secret.database.arn
        description = aws_secretsmanager_secret.database.description
      }
      keycloak_admin = {
        name        = aws_secretsmanager_secret.keycloak_admin.name
        arn         = aws_secretsmanager_secret.keycloak_admin.arn
        description = aws_secretsmanager_secret.keycloak_admin.description
      }
      backend_client_secret = {
        name        = aws_secretsmanager_secret.backend_client_secret.name
        arn         = aws_secretsmanager_secret.backend_client_secret.arn
        description = aws_secretsmanager_secret.backend_client_secret.description
      }
    }
  }
}

# IAM Role Outputs
output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.keystone_ec2_role.arn
}

output "ec2_role_name" {
  description = "Name of the EC2 IAM role"
  value       = aws_iam_role.keystone_ec2_role.name
}

output "secrets_policy_arn" {
  description = "ARN of the secrets manager read policy"
  value       = aws_iam_policy.keystone_secrets_manager_read_policy.arn
}

output "secrets_policy_name" {
  description = "Name of the secrets manager read policy"
  value       = aws_iam_policy.keystone_secrets_manager_read_policy.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = aws_iam_instance_profile.keystone_ec2_profile.arn
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.keystone_ec2_profile.name
}

output "iam_summary" {
  description = "Summary of all created IAM resources"
  value = {
    role = {
      name = aws_iam_role.keystone_ec2_role.name
      arn  = aws_iam_role.keystone_ec2_role.arn
    }
    policy = {
      name = aws_iam_policy.keystone_secrets_manager_read_policy.name
      arn  = aws_iam_policy.keystone_secrets_manager_read_policy.arn
    }
    instance_profile = {
      name = aws_iam_instance_profile.keystone_ec2_profile.name
      arn  = aws_iam_instance_profile.keystone_ec2_profile.arn
    }
  }
}
