locals {
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Module      = "secrets-manager"
    },
    var.additional_tags
  )
}

# RDS Database Secret
resource "aws_secretsmanager_secret" "database" {
  name                    = "${var.project_name}/${var.environment}/database"
  description             = "Stores the username and password for the Keystone RDS database."
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name       = "${var.project_name}-${var.environment}-database-secret"
      Purpose    = "RDS Database Credentials"
      SecretType = "database"
    }
  )
}

resource "aws_secretsmanager_secret_version" "database" {
  secret_id = aws_secretsmanager_secret.database.id
  secret_string = jsonencode({
    username = var.rds_username
    password = var.rds_password
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Keycloak Admin Secret
resource "aws_secretsmanager_secret" "keycloak_admin" {
  name                    = "${var.project_name}/${var.environment}/keycloak_admin"
  description             = "Stores the credentials for the Keycloak service account client."
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name       = "${var.project_name}-${var.environment}-keycloak-admin-secret"
      Purpose    = "Keycloak Admin Credentials"
      SecretType = "application"
    }
  )
}

resource "aws_secretsmanager_secret_version" "keycloak_admin" {
  secret_id = aws_secretsmanager_secret.keycloak_admin.id
  secret_string = jsonencode({
    username = var.keycloak_username
    password = var.keycloak_password
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# SENNA Backend Client Secret
resource "aws_secretsmanager_secret" "backend_client_secret" {
  name                    = "${var.project_name}/${var.environment}/backend_client_secret"
  description             = "Stores the client secret for the SENNA backend service from Keycloak."
  recovery_window_in_days = var.recovery_window_in_days
  kms_key_id              = var.kms_key_id

  tags = merge(
    local.common_tags,
    {
      Name       = "${var.project_name}-${var.environment}-backend-client-secret"
      Purpose    = "SENNA Backend Client Secret"
      SecretType = "application"
    }
  )
}

resource "aws_secretsmanager_secret_version" "backend_client_secret" {
  secret_id = aws_secretsmanager_secret.backend_client_secret.id
  secret_string = jsonencode({
    client_secret = var.senna_backend_client_secret
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# EC2 IAM Role for Secrets Access
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "keystone_ec2_role" {
  name               = "keystone-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(
    local.common_tags,
    {
      Name      = "keystone-ec2-role"
      Purpose   = "EC2 Secrets Manager Access"
      Component = "iam"
    }
  )
}

# IAM Policy for Secrets Manager Access
data "aws_iam_policy_document" "secrets_manager_read" {
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]

    resources = [
      aws_secretsmanager_secret.database.arn,
      aws_secretsmanager_secret.keycloak_admin.arn,
      aws_secretsmanager_secret.backend_client_secret.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:ListSecrets"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "secretsmanager:ResourceTag/Project"
      values   = ["keystone"]
    }
  }
}

resource "aws_iam_policy" "keystone_secrets_manager_read_policy" {
  name        = "keystone-secrets-manager-read-policy"
  description = "Allow reading specific Keystone secrets from AWS Secrets Manager"
  policy      = data.aws_iam_policy_document.secrets_manager_read.json

  tags = merge(
    local.common_tags,
    {
      Name      = "keystone-secrets-manager-read-policy"
      Purpose   = "Secrets Manager Read Access"
      Component = "iam"
    }
  )
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "keystone_secrets_attachment" {
  role       = aws_iam_role.keystone_ec2_role.name
  policy_arn = aws_iam_policy.keystone_secrets_manager_read_policy.arn
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "keystone_ec2_profile" {
  name = "keystone-ec2-profile"
  role = aws_iam_role.keystone_ec2_role.name

  tags = merge(
    local.common_tags,
    {
      Name      = "keystone-ec2-profile"
      Purpose   = "EC2 Instance Profile for Keystone"
      Component = "iam"
    }
  )
}
