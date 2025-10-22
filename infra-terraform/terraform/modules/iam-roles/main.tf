# ===================================
# Local Values
# ===================================

locals {
  # Common naming pattern
  name_prefix = "${var.project_name}-${var.service_name}-${var.environment}"

  # Common tags
  common_tags = merge(var.common_tags, {
    Module      = "iam-roles"
    Service     = var.service_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  })

  # GitHub OIDC subjects
  github_subjects = var.create_github_oidc_role ? flatten([
    for repo in var.github_repositories : [
      for branch in var.github_branches :
      "${var.github_org}/${repo}:ref:refs/heads/${branch}"
    ]
  ]) : []
}

# ===================================
# Data Sources
# ===================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# ===================================
# GitHub OIDC Provider
# ===================================

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-github-oidc-provider"
    Component = "oidc-provider"
    Purpose   = "GitHub Actions authentication"
  })
}

# ===================================
# GitHub Actions ECR Push Role
# ===================================

# Trust policy for GitHub Actions
data "aws_iam_policy_document" "github_actions_assume_role" {
  count = var.create_github_oidc_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.github_subjects
    }
  }
}

# ECR push policy for GitHub Actions
data "aws_iam_policy_document" "github_actions_ecr_push" {
  count = var.create_github_oidc_role ? 1 : 0

  # ECR authentication
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  # ECR repository operations
  dynamic "statement" {
    for_each = length(var.ecr_repository_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchImportLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:ListImages"
      ]
      resources = var.ecr_repository_arns
    }
  }
}

resource "aws_iam_role" "github_actions_ecr_push" {
  count = var.create_github_oidc_role ? 1 : 0

  name               = "${local.name_prefix}-github-actions-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role[0].json
  description        = "IAM role for GitHub Actions to push images to ECR repositories"

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-github-actions-ecr-push"
    Component = "github-actions-role"
    Purpose   = "ECR image push from CI/CD"
  })
}

resource "aws_iam_role_policy" "github_actions_ecr_push" {
  count = var.create_github_oidc_role ? 1 : 0

  name   = "${local.name_prefix}-github-actions-ecr-push-policy"
  role   = aws_iam_role.github_actions_ecr_push[0].id
  policy = data.aws_iam_policy_document.github_actions_ecr_push[0].json
}

# ===================================
# App Runner Access Role (for ECR)
# ===================================

# Trust policy for App Runner service
data "aws_iam_policy_document" "app_runner_access_assume_role" {
  count = var.create_app_runner_access_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["build.apprunner.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "app_runner_access" {
  count = var.create_app_runner_access_role ? 1 : 0

  name               = "${local.name_prefix}-app-runner-access"
  assume_role_policy = data.aws_iam_policy_document.app_runner_access_assume_role[0].json
  description        = "IAM role for App Runner to access ECR repositories"

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-app-runner-access"
    Component = "app-runner-access-role"
    Purpose   = "ECR repository access for App Runner"
  })
}

# Attach the AWS managed policy for ECR read access
resource "aws_iam_role_policy_attachment" "app_runner_ecr_access" {
  count = var.create_app_runner_access_role ? 1 : 0

  role       = aws_iam_role.app_runner_access[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# ===================================
# App Runner Instance Role (for application permissions)
# ===================================

# Trust policy for App Runner tasks
data "aws_iam_policy_document" "app_runner_instance_assume_role" {
  count = var.create_app_runner_instance_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["tasks.apprunner.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# Application permissions policy
data "aws_iam_policy_document" "app_runner_instance_policy" {
  count = var.create_app_runner_instance_role ? 1 : 0

  # Secrets Manager access
  dynamic "statement" {
    for_each = length(var.secrets_manager_secret_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ]
      resources = var.secrets_manager_secret_arns
    }
  }

  # ElastiCache access (if cluster ARN provided)
  dynamic "statement" {
    for_each = var.elasticache_cluster_arn != "" ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "elasticache:DescribeCacheClusters",
        "elasticache:DescribeCacheSubnetGroups"
      ]
      resources = [var.elasticache_cluster_arn]
    }
  }

  # CloudWatch Logs for application logging
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apprunner/${var.service_name}-*"
    ]
  }
}

resource "aws_iam_role" "app_runner_instance" {
  count = var.create_app_runner_instance_role ? 1 : 0

  name               = "${local.name_prefix}-app-runner-instance"
  assume_role_policy = data.aws_iam_policy_document.app_runner_instance_assume_role[0].json
  description        = "IAM role for App Runner service instances to access AWS resources"

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-app-runner-instance"
    Component = "app-runner-instance-role"
    Purpose   = "Application permissions for App Runner services"
  })
}

resource "aws_iam_role_policy" "app_runner_instance" {
  count = var.create_app_runner_instance_role ? 1 : 0

  name   = "${local.name_prefix}-app-runner-instance-policy"
  role   = aws_iam_role.app_runner_instance[0].id
  policy = data.aws_iam_policy_document.app_runner_instance_policy[0].json
}

# Attach additional policies if specified
resource "aws_iam_role_policy_attachment" "app_runner_instance_additional" {
  count = var.create_app_runner_instance_role ? length(var.app_runner_additional_policies) : 0

  role       = aws_iam_role.app_runner_instance[0].name
  policy_arn = var.app_runner_additional_policies[count.index]
}

# ===================================
# EC2 Instance Role and Profile
# ===================================

# Trust policy for EC2 instances
data "aws_iam_policy_document" "ec2_assume_role" {
  count = var.create_ec2_instance_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# EC2 instance permissions policy
data "aws_iam_policy_document" "ec2_instance_policy" {
  count = var.create_ec2_instance_role ? 1 : 0

  # ECR access for pulling images
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = length(var.ecr_repository_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:DescribeRepositories",
        "ecr:DescribeImages",
        "ecr:ListImages"
      ]
      resources = var.ecr_repository_arns
    }
  }

  # Secrets Manager access
  dynamic "statement" {
    for_each = length(var.secrets_manager_secret_arns) > 0 ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecrets"
      ]
      resources = var.secrets_manager_secret_arns
    }
  }

  # ElastiCache access
  dynamic "statement" {
    for_each = var.elasticache_cluster_arn != "" ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "elasticache:DescribeCacheClusters",
        "elasticache:DescribeCacheSubnetGroups",
        "elasticache:DescribeReplicationGroups"
      ]
      resources = [var.elasticache_cluster_arn]
    }
  }

  # CloudWatch Logs
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/ec2/${var.service_name}-*"
    ]
  }

  # CloudWatch Metrics
  statement {
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }

  # SSM for parameter store and session manager
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParametersByPath",
      "ssm:DescribeParameters"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.project_name}/${var.environment}/*"
    ]
  }
}

resource "aws_iam_role" "ec2_instance" {
  count = var.create_ec2_instance_role ? 1 : 0

  name               = "${local.name_prefix}-ec2-instance"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role[0].json
  description        = "IAM role for EC2 instances to access AWS resources"

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ec2-instance"
    Component = "ec2-instance-role"
    Purpose   = "EC2 instance permissions for application workloads"
  })
}

resource "aws_iam_role_policy" "ec2_instance" {
  count = var.create_ec2_instance_role ? 1 : 0

  name   = "${local.name_prefix}-ec2-instance-policy"
  role   = aws_iam_role.ec2_instance[0].id
  policy = data.aws_iam_policy_document.ec2_instance_policy[0].json
}

# Attach additional policies if specified
resource "aws_iam_role_policy_attachment" "ec2_instance_additional" {
  count = var.create_ec2_instance_role ? length(var.ec2_additional_policies) : 0

  role       = aws_iam_role.ec2_instance[0].name
  policy_arn = var.ec2_additional_policies[count.index]
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "ec2_instance" {
  count = var.create_ec2_instance_role ? 1 : 0

  name = "${local.name_prefix}-ec2-instance-profile"
  role = aws_iam_role.ec2_instance[0].name

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ec2-instance-profile"
    Component = "ec2-instance-profile"
    Purpose   = "EC2 instance profile for application workloads"
  })
}

# ===================================
# EC2 Worker Role (based on UAT senna-ec2-worker-role-uat)
# ===================================

# Trust policy for EC2 worker instances
data "aws_iam_policy_document" "ec2_worker_assume_role" {
  count = var.create_ec2_worker_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "ec2_worker" {
  count = var.create_ec2_worker_role ? 1 : 0

  name               = "${local.name_prefix}-ec2-worker-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_worker_assume_role[0].json
  description        = "IAM role for SENNA EC2 worker instances with ECR access"

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ec2-worker-role"
    Component = "ec2-worker-role"
    Purpose   = "EC2 worker instances for SENNA application"
  })
}

# Attach AWS managed policy for ECR read-only access
resource "aws_iam_role_policy_attachment" "ec2_worker_ecr_readonly" {
  count = var.create_ec2_worker_role ? 1 : 0

  role       = aws_iam_role.ec2_worker[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EC2 Worker Instance Profile
resource "aws_iam_instance_profile" "ec2_worker" {
  count = var.create_ec2_worker_role ? 1 : 0

  name = "${local.name_prefix}-ec2-worker-profile"
  role = aws_iam_role.ec2_worker[0].name

  tags = merge(local.common_tags, {
    Name      = "${local.name_prefix}-ec2-worker-profile"
    Component = "ec2-worker-instance-profile"
    Purpose   = "EC2 instance profile for SENNA worker instances"
  })
}
