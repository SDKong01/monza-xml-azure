# ===================================
# Local Values
# ===================================

locals {
  # Common naming pattern for service-specific resources
  name_prefix = "${var.project_name}-${var.service_name}-${var.environment}"

  # Generic naming pattern for shared IAM roles (service-agnostic)
  shared_name_prefix = "${var.project_name}-${var.environment}"

  # Keycloak-specific naming pattern
  keycloak_name_prefix = "${var.project_name}-keycloak-${var.environment}"

  # Kainam Platform-specific naming pattern
  kainam_platform_name_prefix = "${var.project_name}-kainam-platform-${var.environment}"

  # Common tags
  common_tags = merge(var.common_tags, {
    Module      = "codepipeline"
    Environment = var.environment
    Project     = var.project_name
    Service     = var.service_name
    ManagedBy   = "Terraform"
  })

  # Shared resource tags (without service-specific info)
  shared_tags = merge(var.common_tags, {
    Module      = "codepipeline"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })

  # Common CodeBuild environment variables
  common_build_env_vars = [
    {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
      type  = "PLAINTEXT"
    },
    {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
      type  = "PLAINTEXT"
    },
    {
      name  = "IMAGE_TAG"
      value = "latest"
      type  = "PLAINTEXT"
    }
  ]
}

# ===================================
# Data Sources
# ===================================

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ===================================
# IAM Roles for CodePipeline
# ===================================

# CodePipeline Service Role (Shared across all services)
resource "aws_iam_role" "codepipeline_role" {
  name = "${local.shared_name_prefix}-codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.shared_tags, {
    Name      = "${local.shared_name_prefix}-codepipeline-role"
    Component = "codepipeline-role"
    Purpose   = "Shared service role for CodePipeline execution across all services"
  })
}

# CodePipeline Policy (Shared across all services)
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "${local.shared_name_prefix}-codepipeline-policy"
  role = aws_iam_role.codepipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Abort*",
          "s3:DeleteObject*",
          "s3:GetBucket*",
          "s3:GetObject*",
          "s3:List*",
          "s3:PutObject",
          "s3:PutObjectLegalHold",
          "s3:PutObjectRetention",
          "s3:PutObjectTagging",
          "s3:PutObjectVersionTagging"
        ]
        Resource = [
          aws_s3_bucket.codepipeline_artifacts.arn,
          "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codebuild:BatchGetBuilds",
          "codebuild:StartBuild"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "codeconnections:UseConnection",
          "codestar-connections:UseConnection"
        ]
        Resource = var.github_connection_arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codepipeline/*"
        ]
      }
    ]
  })
}

# ===================================
# IAM Roles for CodeBuild
# ===================================

# CodeBuild Service Role (Shared across all services)
resource "aws_iam_role" "codebuild_role" {
  name = "${local.shared_name_prefix}-codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codebuild.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.shared_tags, {
    Name      = "${local.shared_name_prefix}-codebuild-role"
    Component = "codebuild-role"
    Purpose   = "Shared service role for CodeBuild execution across all services"
  })
}

# CodeBuild Policy (Shared across all services)
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "${local.shared_name_prefix}-codebuild-policy"
  role = aws_iam_role.codebuild_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/codebuild/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ]
        Resource = "${aws_s3_bucket.codepipeline_artifacts.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetAuthorizationToken",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      }
    ]
  })
}

# ===================================
# S3 Bucket for CodePipeline Artifacts
# ===================================

resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "${local.name_prefix}-codepipeline-artifacts"

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-codepipeline-artifacts"
    Component = "s3-artifacts"
    Purpose   = "CodePipeline artifacts storage"
  })
}

resource "aws_s3_bucket_versioning" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "codepipeline_artifacts" {
  bucket = aws_s3_bucket.codepipeline_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ===================================
# CodeBuild Projects
# ===================================

# Frontend CodeBuild Project
resource "aws_codebuild_project" "frontend" {
  count = var.create_frontend_pipeline ? 1 : 0

  name         = "${local.name_prefix}-frontend-build"
  description  = "Build project for SENNA frontend Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = concat(local.common_build_env_vars, [
        {
          name  = "IMAGE_REPO_NAME"
          value = split("/", var.ecr_repository_urls.frontend)[1]
          type  = "PLAINTEXT"
        }
      ], var.frontend_environment_variables)
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2

      env:
        variables:
          IMAGE_REPO_NAME: "senna-front-ecr-dev"
          IMAGE_TAG: "dev"
          AWS_REGION: "us-east-2"
          NEXT_PUBLIC_BASE_BACK_URL: "https://wdtyf4qmpn.us-east-2.awsapprunner.com"
          BASE_SECRET: "g833lwJ3IhS7LG1Xi9qHIMIlV9lDnsr1"
          NEXTAUTH_URL: "https://ceamr2gi9c.us-east-2.awsapprunner.com/api/auth"
          NEXT_PUBLIC_IS_DUMMY: "false"
          NEXT_PUBLIC_PREFIX_BACK_URL: "/v1"
          NEXT_PUBLIC_FAVICON_URL: "/images/favicon.ico"
          NEXT_PUBLIC_LOGO_URL: "/images/SENNA-Logo.png"
          NEXT_PUBLIC_BASE_KIMBALL_URL: "https://wdtyf4qmpn.us-east-2.awsapprunner.com"

      phases:
        pre_build:
          commands:
            - echo "Logging Amazon ECR..."
            - aws --version
            - echo "Clearing any existing Next.js cache..."
            - rm -rf .next
            - REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $IMAGE_REPO_NAME --region $AWS_REGION --query "repositories[0].repositoryUri" --output text)
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI
        build:
          commands:
            - echo "Building Docker image..."
            - docker build --no-cache -t $REPOSITORY_URI:$IMAGE_TAG --build-arg BASE_SECRET="$BASE_SECRET" --build-arg NEXTAUTH_URL="$NEXTAUTH_URL" --build-arg NEXT_PUBLIC_BASE_BACK_URL="$NEXT_PUBLIC_BASE_BACK_URL" --build-arg NEXT_PUBLIC_IS_DUMMY="$NEXT_PUBLIC_IS_DUMMY" --build-arg NEXT_PUBLIC_PREFIX_BACK_URL="$NEXT_PUBLIC_PREFIX_BACK_URL" --build-arg NEXT_PUBLIC_LOGO_URL="$NEXT_PUBLIC_LOGO_URL" --build-arg NEXT_PUBLIC_BASE_KIMBALL_URL="$NEXT_PUBLIC_BASE_KIMBALL_URL" --build-arg NEXT_PUBLIC_FAVICON_URL="$NEXT_PUBLIC_FAVICON_URL" .
        post_build:
          commands:
            - echo "Pushing image to ECR..."
            - docker push $REPOSITORY_URI:$IMAGE_TAG
            - echo "Image pushed successfully"

      artifacts:
        files:
          - '**/*'
    EOT
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-frontend-build"
    Component = "codebuild-frontend"
    Purpose   = "Frontend Docker image build"
  })
}

# API CodeBuild Project
resource "aws_codebuild_project" "api" {
  count = var.create_api_pipeline ? 1 : 0

  name         = "${local.name_prefix}-api-build"
  description  = "Build project for SENNA API Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = concat(local.common_build_env_vars, [
        {
          name  = "IMAGE_REPO_NAME"
          value = split("/", var.ecr_repository_urls.api)[1]
          type  = "PLAINTEXT"
        }
      ], var.api_environment_variables)
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2

      env:
        variables:
          IMAGE_REPO_NAME: "senna-api-ecr-dev"
          IMAGE_TAG: "dev"
          AWS_REGION: "us-east-2"

      phases:
        pre_build:
          commands:
            - echo "Logging Amazon ECR..."
            - aws --version
            - REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $IMAGE_REPO_NAME --region $AWS_REGION --query "repositories[0].repositoryUri" --output text)
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI
        build:
          commands:
            - echo "Building Docker image..."
            - docker build -t $REPOSITORY_URI:$IMAGE_TAG .
        post_build:
          commands:
            - echo "Pushing image to ECR..."
            - docker push $REPOSITORY_URI:$IMAGE_TAG
            - echo "Image pushed successfully"

      artifacts:
        files:
          - '**/*'
    EOT
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-api-build"
    Component = "codebuild-api"
    Purpose   = "API Docker image build"
  })
}

# Models CodeBuild Project
resource "aws_codebuild_project" "models" {
  count = var.create_models_pipeline ? 1 : 0

  name         = "${local.name_prefix}-models-build"
  description  = "Build project for SENNA models Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = concat(local.common_build_env_vars, [
        {
          name  = "IMAGE_REPO_NAME"
          value = split("/", var.ecr_repository_urls.models)[1]
          type  = "PLAINTEXT"
        }
      ], var.models_environment_variables)
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2

      env:
        variables:
          IMAGE_REPO_NAME: "senna-models-ecr-dev"
          IMAGE_TAG: "dev"
          AWS_REGION: "us-east-2"

      phases:
        pre_build:
          commands:
            - echo "Logging Amazon ECR..."
            - aws --version
            - REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $IMAGE_REPO_NAME --region $AWS_REGION --query "repositories[0].repositoryUri" --output text)
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI
        build:
          commands:
            - echo "Building Docker image..."
            - docker build -t $REPOSITORY_URI:$IMAGE_TAG -f ./infrastructure/celery/time_series/Dockerfile .
        post_build:
          commands:
            - echo "Pushing image to ECR..."
            - docker push $REPOSITORY_URI:$IMAGE_TAG
            - echo "Image pushed successfully"

      artifacts:
        files:
          - '**/*'
    EOT
  }

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-models-build"
    Component = "codebuild-models"
    Purpose   = "Models Docker image build"
  })
}

# Keycloak CodeBuild Project
resource "aws_codebuild_project" "keycloak" {
  count = var.create_keycloak_pipeline ? 1 : 0

  name         = "${local.keycloak_name_prefix}-build"
  description  = "Build project for Keycloak authentication Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = concat(local.common_build_env_vars, [
        {
          name  = "IMAGE_REPO_NAME"
          value = "keycloak-ecr-dev"
          type  = "PLAINTEXT"
        }
      ])
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2

      env:
        variables:
          IMAGE_REPO_NAME: "keycloak-ecr-dev"
          IMAGE_TAG: "latest"
          AWS_REGION: "us-east-2"

      phases:
        pre_build:
          commands:
            # Monorepo path filtering - only proceed if authentication files changed
            - |
              if git diff --name-only HEAD~1 HEAD | grep -E '^authentication/'; then
                echo "Authentication files changed, proceeding with build"
              else
                echo "No authentication files changed, skipping build"
                exit 0
              fi
            - echo "Logging into Amazon ECR..."
            - aws --version
            - REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $IMAGE_REPO_NAME --region $AWS_REGION --query "repositories[0].repositoryUri" --output text)
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI
        build:
          commands:
            - echo "Building Keycloak Docker image..."
            - cd authentication
            - docker build -t $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION .
            - docker tag $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION $REPOSITORY_URI:$IMAGE_TAG
        post_build:
          commands:
            - echo "Pushing image to ECR..."
            - docker push $REPOSITORY_URI:$CODEBUILD_RESOLVED_SOURCE_VERSION
            - docker push $REPOSITORY_URI:$IMAGE_TAG
            - echo "Keycloak image pushed successfully"

      artifacts:
        files:
          - '**/*'
    EOT
  }

  tags = merge(local.shared_tags, {
    Name      = "${local.keycloak_name_prefix}-build"
    Component = "codebuild-keycloak"
    Purpose   = "Keycloak authentication Docker image build"
    Service   = "keycloak"
  })
}

# Kainam Platform API CodeBuild Project
resource "aws_codebuild_project" "kainam_platform_api" {
  count = var.create_kainam_platform_api_pipeline ? 1 : 0

  name         = "kainam-platform-${var.environment}-api-build"
  description  = "Build project for Kainam Platform API Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = concat(local.common_build_env_vars, [
        {
          name  = "IMAGE_REPO_NAME"
          value = split("/", var.kainam_platform_ecr_repository_urls.api)[1]
          type  = "PLAINTEXT"
        }
      ], var.kainam_platform_api_environment_variables)
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2

      env:
        variables:
          IMAGE_REPO_NAME: "kainam-platform-api-ecr-dev"
          IMAGE_TAG: "dev"
          AWS_REGION: "us-east-2"

      phases:
        pre_build:
          commands:
            - echo "Logging Amazon ECR..."
            - aws --version
            - REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $IMAGE_REPO_NAME --region $AWS_REGION --query "repositories[0].repositoryUri" --output text)
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI
        build:
          commands:
            - echo "Building Kainam Platform API Docker image..."
            - docker build -t $REPOSITORY_URI:$IMAGE_TAG .
        post_build:
          commands:
            - echo "Pushing image to ECR..."
            - docker push $REPOSITORY_URI:$IMAGE_TAG
            - echo "Kainam Platform API image pushed successfully"

      artifacts:
        files:
          - '**/*'
    EOT
  }

  tags = merge(local.common_tags, {
    Name      = "kainam-platform-${var.environment}-api-build"
    Component = "codebuild-kainam-platform-api"
    Purpose   = "Kainam Platform API Docker image build"
    Service   = "kainam-platform"
  })
}

# Kainam Platform Frontend CodeBuild Project
resource "aws_codebuild_project" "kainam_platform_frontend" {
  count = var.create_kainam_platform_frontend_pipeline ? 1 : 0

  name         = "kainam-platform-${var.environment}-front-build"
  description  = "Build project for Kainam Platform frontend Docker image"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    dynamic "environment_variable" {
      for_each = concat(local.common_build_env_vars, [
        {
          name  = "IMAGE_REPO_NAME"
          value = split("/", var.kainam_platform_ecr_repository_urls.frontend)[1]
          type  = "PLAINTEXT"
        }
      ], var.kainam_platform_frontend_environment_variables)
      content {
        name  = environment_variable.value.name
        value = environment_variable.value.value
        type  = environment_variable.value.type
      }
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2

      env:
        variables:
          IMAGE_REPO_NAME: "kainam-platform-front-ecr-dev"
          IMAGE_TAG: "dev"
          AWS_REGION: "us-east-2"
          NEXT_PUBLIC_SENNA_API_URL: "placeholder_url"
          NEXT_PUBLIC_MONZA_API_URL: "placeholder_url"
          NEXT_PUBLIC_KIMBALL_API_URL: "placeholder_url"

      phases:
        pre_build:
          commands:
            - echo "Logging Amazon ECR..."
            - aws --version
            - echo "Clearing any existing Next.js cache..."
            - rm -rf .next
            - REPOSITORY_URI=$(aws ecr describe-repositories --repository-names $IMAGE_REPO_NAME --region $AWS_REGION --query "repositories[0].repositoryUri" --output text)
            - aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $REPOSITORY_URI
        build:
          commands:
            - echo "Building Kainam Platform Frontend Docker image..."
            - docker build --no-cache -t $REPOSITORY_URI:$IMAGE_TAG --build-arg NEXT_PUBLIC_SENNA_API_URL="$NEXT_PUBLIC_SENNA_API_URL" --build-arg NEXT_PUBLIC_MONZA_API_URL="$NEXT_PUBLIC_MONZA_API_URL" --build-arg NEXT_PUBLIC_KIMBALL_API_URL="$NEXT_PUBLIC_KIMBALL_API_URL" .
        post_build:
          commands:
            - echo "Pushing image to ECR..."
            - docker push $REPOSITORY_URI:$IMAGE_TAG
            - echo "Kainam Platform Frontend image pushed successfully"

      artifacts:
        files:
          - '**/*'
    EOT
  }

  tags = merge(local.common_tags, {
    Name      = "kainam-platform-${var.environment}-front-build"
    Component = "codebuild-kainam-platform-frontend"
    Purpose   = "Kainam Platform frontend Docker image build"
    Service   = "kainam-platform"
  })
}

# ===================================
# CodePipeline Pipelines
# ===================================

# Frontend Pipeline
resource "aws_codepipeline" "frontend" {
  count = var.create_frontend_pipeline ? 1 : 0

  name     = "${var.service_name}-front-cb-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.frontend_repository
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.frontend[0].name
      }
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${var.service_name}-front-cb-pipeline-${var.environment}"
    Component = "codepipeline-frontend"
    Purpose   = "Frontend CI/CD pipeline"
  })
}

# API Pipeline
resource "aws_codepipeline" "api" {
  count = var.create_api_pipeline ? 1 : 0

  name     = "${var.service_name}-api-cb-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.api_repository
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.api[0].name
      }
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${var.service_name}-api-cb-pipeline-${var.environment}"
    Component = "codepipeline-api"
    Purpose   = "API CI/CD pipeline"
  })
}

# Models Pipeline
resource "aws_codepipeline" "models" {
  count = var.create_models_pipeline ? 1 : 0

  name     = "${var.service_name}-models-cb-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.models_repository
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.models[0].name
      }
    }
  }

  tags = merge(local.common_tags, {
    Name      = "${var.service_name}-models-cb-pipeline-${var.environment}"
    Component = "codepipeline-models"
    Purpose   = "Models CI/CD pipeline"
  })
}

# Keycloak Pipeline
resource "aws_codepipeline" "keycloak" {
  count = var.create_keycloak_pipeline ? 1 : 0

  name     = "keycloak-cb-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.keycloak_repository
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.keycloak[0].name
      }
    }
  }

  tags = merge(local.shared_tags, {
    Name      = "keycloak-cb-pipeline-${var.environment}"
    Component = "codepipeline-keycloak"
    Purpose   = "Keycloak authentication CI/CD pipeline"
    Service   = "keycloak"
  })
}

# Kainam Platform API Pipeline
resource "aws_codepipeline" "kainam_platform_api" {
  count = var.create_kainam_platform_api_pipeline ? 1 : 0

  name     = "kainam-platform-api-cb-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.kainam_platform_api_repository
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.kainam_platform_api[0].name
      }
    }
  }

  tags = merge(local.common_tags, {
    Name      = "kainam-platform-api-cb-pipeline-${var.environment}"
    Component = "codepipeline-kainam-platform-api"
    Purpose   = "Kainam Platform API CI/CD pipeline"
    Service   = "kainam-platform"
  })
}

# Kainam Platform Frontend Pipeline
resource "aws_codepipeline" "kainam_platform_frontend" {
  count = var.create_kainam_platform_frontend_pipeline ? 1 : 0

  name     = "kainam-platform-frontend-cb-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.codepipeline_artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.kainam_platform_frontend_repository
        BranchName       = var.source_branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name            = "Build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.kainam_platform_frontend[0].name
      }
    }
  }

  tags = merge(local.common_tags, {
    Name      = "kainam-platform-frontend-cb-pipeline-${var.environment}"
    Component = "codepipeline-kainam-platform-frontend"
    Purpose   = "Kainam Platform frontend CI/CD pipeline"
    Service   = "kainam-platform"
  })
}
