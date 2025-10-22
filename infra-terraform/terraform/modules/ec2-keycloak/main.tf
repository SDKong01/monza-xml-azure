# EC2 Keycloak Module - Main Resources
# Provides Keycloak authentication service on EC2 with Docker deployment

# ===================================
# DATA SOURCES
# ===================================

# Get current AWS caller identity for account ID
data "aws_caller_identity" "current" {}

# Get current AWS region
data "aws_region" "current" {}

# Get subnet information for availability zone
data "aws_subnet" "selected" {
  id = var.subnet_id
}

# ===================================
# LOCAL VALUES
# ===================================

locals {
  # Naming patterns following project standards
  instance_name = "${var.project_name}-keycloak-${var.environment}"

  # Common tags for all resources
  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      Service     = "keycloak"
      ManagedBy   = "Terraform"
      Module      = "ec2-keycloak"
      Purpose     = "Authentication service"
    },
    var.additional_tags
  )

  # Template variables for user data script
  template_vars = {
    # Environment configuration
    environment    = var.environment
    project_name   = var.project_name
    aws_region     = var.aws_region
    aws_account_id = var.aws_account_id

    # ECR configuration
    ecr_repository = split("/", var.ecr_repository_url)[1]
    image_tag      = var.image_tag

    # Database configuration
    rds_endpoint = var.rds_endpoint
    db_name      = var.database_name
    db_port      = tostring(var.database_port)

    # Keycloak configuration
    kc_hostname    = var.keycloak_hostname
    kc_http_port   = tostring(var.keycloak_http_port)
    container_name = var.container_name

    # Secrets Manager configuration
    database_secret_name = var.database_secret_name
    keycloak_secret_name = var.keycloak_secret_name
  }
}

# ===================================
# USER DATA TEMPLATE
# ===================================

# Render the deployment script template with environment-specific values
data "template_file" "user_data" {
  template = file("${path.module}/../../../scripts/deploy_keycloak_bootstrap.sh.tpl")
  vars     = local.template_vars
}

# ===================================
# SECURITY GROUP
# ===================================

# Security group for Keycloak EC2 instance
resource "aws_security_group" "keycloak" {
  name_prefix = "${local.instance_name}-sg-"
  description = "Security group for Keycloak authentication service"
  vpc_id      = var.vpc_id

  # Ingress rule: Allow HTTP traffic from ALB only
  ingress {
    description     = "HTTP from ALB"
    from_port       = var.keycloak_http_port
    to_port         = var.keycloak_http_port
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  # Ingress rule: Allow SSH access from trusted IPs (conditional)
  dynamic "ingress" {
    for_each = var.enable_ssh_access && length(var.ssh_trusted_ip_ranges) > 0 ? [1] : []
    content {
      description = "SSH from trusted IPs"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_trusted_ip_ranges
    }
  }

  # Egress rule: Allow all outbound traffic for package updates and ECR pulls
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name      = "${local.instance_name}-sg"
    Component = "security-group"
    Purpose   = "Keycloak instance network security"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ===================================
# IAM ROLE AND POLICIES
# ===================================

# IAM assume role policy document for EC2
data "aws_iam_policy_document" "ec2_assume_role" {
  count = var.create_iam_role ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

# IAM role for Keycloak EC2 instance
resource "aws_iam_role" "keycloak_ec2_role" {
  count = var.create_iam_role ? 1 : 0

  name               = "${local.instance_name}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role[0].json
  description        = "IAM role for Keycloak EC2 instance"

  tags = merge(local.common_tags, {
    Name      = "${local.instance_name}-role"
    Component = "iam-role"
    Purpose   = "Keycloak instance permissions"
  })
}

# IAM policy document for Keycloak instance permissions
data "aws_iam_policy_document" "keycloak_policy" {
  count = var.create_iam_role ? 1 : 0

  # ECR permissions for pulling Docker images
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage"
    ]
    resources = ["*"]
  }

  # Secrets Manager permissions for database and Keycloak credentials
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.database_secret_name}*",
      "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:${var.keycloak_secret_name}*"
    ]
  }

  # CloudWatch Logs permissions for application logging
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/ec2/keycloak*"
    ]
  }

  # EC2 permissions for instance metadata and self-management
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags"
    ]
    resources = ["*"]
  }

  # AWS Systems Manager Session Manager permissions
  statement {
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ssm:DescribeInstanceInformation",
      "ssm:DescribeAssociation",
      "ssm:ListAssociations",
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }
}

# IAM policy for Keycloak instance
resource "aws_iam_policy" "keycloak_ec2_policy" {
  count = var.create_iam_role ? 1 : 0

  name        = "${local.instance_name}-policy"
  description = "IAM policy for Keycloak EC2 instance"
  policy      = data.aws_iam_policy_document.keycloak_policy[0].json

  tags = merge(local.common_tags, {
    Name      = "${local.instance_name}-policy"
    Component = "iam-policy"
    Purpose   = "Keycloak instance permissions"
  })
}

# Attach custom policy to IAM role
resource "aws_iam_role_policy_attachment" "keycloak_custom" {
  count = var.create_iam_role ? 1 : 0

  role       = aws_iam_role.keycloak_ec2_role[0].name
  policy_arn = aws_iam_policy.keycloak_ec2_policy[0].arn
}

# Attach additional IAM policies if specified
resource "aws_iam_role_policy_attachment" "keycloak_additional" {
  count = var.create_iam_role ? length(var.additional_iam_policies) : 0

  role       = aws_iam_role.keycloak_ec2_role[0].name
  policy_arn = var.additional_iam_policies[count.index]
}

# IAM instance profile for EC2 instance
resource "aws_iam_instance_profile" "keycloak_ec2_profile" {
  count = var.create_iam_role ? 1 : 0

  name = "${local.instance_name}-profile"
  role = aws_iam_role.keycloak_ec2_role[0].name

  tags = merge(local.common_tags, {
    Name      = "${local.instance_name}-profile"
    Component = "iam-instance-profile"
    Purpose   = "Keycloak instance profile"
  })
}

# ===================================
# SSH KEY PAIR
# ===================================

# SSH Key Pair for dedicated Keycloak instance access
resource "aws_key_pair" "keycloak_ssh" {
  count      = var.ssh_public_key != null ? 1 : 0
  key_name   = "${local.instance_name}-ssh-key"
  public_key = var.ssh_public_key

  tags = merge(local.common_tags, {
    Name      = "${local.instance_name}-ssh-key"
    Component = "ssh-key-pair"
    Purpose   = "Keycloak instance SSH access"
  })
}

# ===================================
# EC2 INSTANCE
# ===================================

# Keycloak EC2 instance
resource "aws_instance" "keycloak" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # Security groups
  vpc_security_group_ids = concat(
    [aws_security_group.keycloak.id],
    var.additional_security_group_ids
  )

  # IAM instance profile
  iam_instance_profile = var.create_iam_role ? aws_iam_instance_profile.keycloak_ec2_profile[0].name : var.existing_iam_instance_profile

  # SSH key pair (dedicated key takes precedence over provided key_pair_name)
  key_name = var.ssh_public_key != null ? aws_key_pair.keycloak_ssh[0].key_name : var.key_pair_name

  # Network configuration
  associate_public_ip_address = var.associate_public_ip_address

  # User data for automated deployment
  user_data = base64encode(data.template_file.user_data.rendered)

  # Monitoring
  monitoring = var.enable_detailed_monitoring

  # Root volume configuration
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = var.root_volume_encrypted

    tags = merge(local.common_tags, {
      Name      = "${local.instance_name}-root-volume"
      Component = "ebs-volume"
      Purpose   = "Keycloak instance root storage"
    })
  }

  # Instance tags
  tags = merge(local.common_tags, {
    Name      = local.instance_name
    Component = "ec2-instance"
    Purpose   = "Keycloak authentication service"
  })

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      # Ignore changes to user_data to prevent unnecessary instance replacement
      user_data
    ]
  }

  # Dependencies
  depends_on = [
    aws_iam_instance_profile.keycloak_ec2_profile,
    aws_security_group.keycloak
  ]
}
