# ECR Module Main Configuration
# Terraform module for managing AWS Elastic Container Registry (ECR) repositories

# API Repository
resource "aws_ecr_repository" "api" {
  count = var.create_api_repository ? 1 : 0

  name                 = "${var.service_name}-api-ecr-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_image_scan_on_push
  }

  encryption_configuration {
    encryption_type = var.repository_encryption_type
    kms_key         = var.repository_encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(var.common_tags, {
    Name      = "${var.service_name}-api-ecr-${var.environment}"
    Module    = "ecr"
    Service   = var.service_name
    Component = "api-repository"
    ManagedBy = "Terraform"
  })
}

# Frontend Repository
resource "aws_ecr_repository" "frontend" {
  count = var.create_frontend_repository ? 1 : 0

  name                 = "${var.service_name}-front-ecr-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_image_scan_on_push
  }

  encryption_configuration {
    encryption_type = var.repository_encryption_type
    kms_key         = var.repository_encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(var.common_tags, {
    Name      = "${var.service_name}-front-ecr-${var.environment}"
    Module    = "ecr"
    Service   = var.service_name
    Component = "frontend-repository"
    ManagedBy = "Terraform"
  })
}

# Models Repository
resource "aws_ecr_repository" "models" {
  count = var.create_models_repository ? 1 : 0

  name                 = "${var.service_name}-models-ecr-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_image_scan_on_push
  }

  encryption_configuration {
    encryption_type = var.repository_encryption_type
    kms_key         = var.repository_encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(var.common_tags, {
    Name      = "${var.service_name}-models-ecr-${var.environment}"
    Module    = "ecr"
    Service   = var.service_name
    Component = "models-repository"
    ManagedBy = "Terraform"
  })
}

# Keycloak Repository
resource "aws_ecr_repository" "keycloak" {
  count = var.create_keycloak_repository ? 1 : 0

  name                 = "keycloak-ecr-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_image_scan_on_push
  }

  encryption_configuration {
    encryption_type = var.repository_encryption_type
    kms_key         = var.repository_encryption_type == "KMS" ? var.kms_key_arn : null
  }

  tags = merge(var.common_tags, {
    Name      = "keycloak-ecr-${var.environment}"
    Module    = "ecr"
    Service   = "authentication"
    Component = "keycloak-repository"
    ManagedBy = "Terraform"
  })
}

# Lifecycle Policy for API Repository
resource "aws_ecr_lifecycle_policy" "api" {
  count      = var.create_api_repository ? 1 : 0
  repository = aws_ecr_repository.api[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = var.image_retention_count
      }
      action = {
        type = "expire"
      }
      }, {
      rulePriority = 2
      description  = "Delete untagged images older than 1 day"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 1
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Lifecycle Policy for Frontend Repository
resource "aws_ecr_lifecycle_policy" "frontend" {
  count      = var.create_frontend_repository ? 1 : 0
  repository = aws_ecr_repository.frontend[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = var.image_retention_count
      }
      action = {
        type = "expire"
      }
      }, {
      rulePriority = 2
      description  = "Delete untagged images older than 1 day"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 1
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Lifecycle Policy for Models Repository
resource "aws_ecr_lifecycle_policy" "models" {
  count      = var.create_models_repository ? 1 : 0
  repository = aws_ecr_repository.models[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = var.image_retention_count
      }
      action = {
        type = "expire"
      }
      }, {
      rulePriority = 2
      description  = "Delete untagged images older than 1 day"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 1
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Lifecycle Policy for Keycloak Repository
resource "aws_ecr_lifecycle_policy" "keycloak" {
  count      = var.create_keycloak_repository ? 1 : 0
  repository = aws_ecr_repository.keycloak[0].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last ${var.image_retention_count} images"
      selection = {
        tagStatus     = "tagged"
        tagPrefixList = ["v"]
        countType     = "imageCountMoreThan"
        countNumber   = var.image_retention_count
      }
      action = {
        type = "expire"
      }
      }, {
      rulePriority = 2
      description  = "Delete untagged images older than 1 day"
      selection = {
        tagStatus   = "untagged"
        countType   = "sinceImagePushed"
        countUnit   = "days"
        countNumber = 1
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# Repository Policy for GitHub Actions Access (if principals provided)
resource "aws_ecr_repository_policy" "github_actions_api" {
  count      = var.create_api_repository && length(var.github_actions_principals) > 0 ? 1 : 0
  repository = aws_ecr_repository.api[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "GitHubActionsECRAccess"
      Effect = "Allow"
      Principal = {
        AWS = var.github_actions_principals
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }]
  })
}

resource "aws_ecr_repository_policy" "github_actions_frontend" {
  count      = var.create_frontend_repository && length(var.github_actions_principals) > 0 ? 1 : 0
  repository = aws_ecr_repository.frontend[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "GitHubActionsECRAccess"
      Effect = "Allow"
      Principal = {
        AWS = var.github_actions_principals
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }]
  })
}

resource "aws_ecr_repository_policy" "github_actions_models" {
  count      = var.create_models_repository && length(var.github_actions_principals) > 0 ? 1 : 0
  repository = aws_ecr_repository.models[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "GitHubActionsECRAccess"
      Effect = "Allow"
      Principal = {
        AWS = var.github_actions_principals
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }]
  })
}

resource "aws_ecr_repository_policy" "github_actions_keycloak" {
  count      = var.create_keycloak_repository && length(var.github_actions_principals) > 0 ? 1 : 0
  repository = aws_ecr_repository.keycloak[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "GitHubActionsECRAccess"
      Effect = "Allow"
      Principal = {
        AWS = var.github_actions_principals
      }
      Action = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }]
  })
}
