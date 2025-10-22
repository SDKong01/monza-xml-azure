# EC2 Instance Module
# Provides a flexible, loosely-coupled EC2 instance with optional security groups, IAM roles, and key pairs



# Data source for latest Amazon Linux 2023 AMI if no AMI ID is provided
data "aws_ami" "amazon_linux" {
  count       = var.ami_id == null ? 1 : 0
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Local values for resource naming and tagging
locals {
  instance_name       = "${var.project_name}-${var.instance_name}-${var.environment}"
  security_group_name = var.security_group_name != null ? "${var.project_name}-${var.security_group_name}-${var.environment}" : "${local.instance_name}-sg"
  iam_role_name       = var.iam_role_name != null ? "${var.project_name}-${var.iam_role_name}-${var.environment}" : "${local.instance_name}-role"
  key_pair_name       = var.key_pair_name != null ? "${var.project_name}-${var.key_pair_name}-${var.environment}" : "${local.instance_name}-key"

  common_tags = merge(
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "ec2-instance"
    },
    var.additional_tags
  )
}

# Security Group (optional)
resource "aws_security_group" "this" {
  count       = var.create_security_group ? 1 : 0
  name        = local.security_group_name
  description = "Security group for ${local.instance_name} EC2 instance"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, {
    Name = local.security_group_name
  })
}

# Security Group Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "this" {
  count             = var.create_security_group ? length(var.ingress_rules) : 0
  security_group_id = aws_security_group.this[0].id

  description = var.ingress_rules[count.index].description
  from_port   = var.ingress_rules[count.index].from_port
  to_port     = var.ingress_rules[count.index].to_port
  ip_protocol = var.ingress_rules[count.index].protocol
  cidr_ipv4   = var.ingress_rules[count.index].cidr_blocks[0]

  tags = merge(local.common_tags, {
    Name = "${local.security_group_name}-ingress-${count.index + 1}"
  })
}

# Security Group Egress Rules
resource "aws_vpc_security_group_egress_rule" "this" {
  count             = var.create_security_group ? length(var.egress_rules) : 0
  security_group_id = aws_security_group.this[0].id

  description = var.egress_rules[count.index].description
  from_port   = var.egress_rules[count.index].from_port
  to_port     = var.egress_rules[count.index].to_port
  ip_protocol = var.egress_rules[count.index].protocol
  cidr_ipv4   = var.egress_rules[count.index].cidr_blocks[0]

  tags = merge(local.common_tags, {
    Name = "${local.security_group_name}-egress-${count.index + 1}"
  })
}

# IAM Role (optional)
resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0
  name  = local.iam_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = local.iam_role_name
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "this" {
  count = var.create_iam_role ? 1 : 0
  name  = "${local.iam_role_name}-profile"
  role  = aws_iam_role.this[0].name

  tags = merge(local.common_tags, {
    Name = "${local.iam_role_name}-profile"
  })
}

# Attach AWS Managed Policies
resource "aws_iam_role_policy_attachment" "managed_policies" {
  count      = var.create_iam_role ? length(var.iam_managed_policy_arns) : 0
  role       = aws_iam_role.this[0].name
  policy_arn = var.iam_managed_policy_arns[count.index]
}

# Create Custom IAM Policies
resource "aws_iam_policy" "custom_policies" {
  count       = var.create_iam_role ? length(var.iam_custom_policies) : 0
  name        = "${local.iam_role_name}-${var.iam_custom_policies[count.index].name}"
  description = var.iam_custom_policies[count.index].description
  policy      = var.iam_custom_policies[count.index].policy_json

  tags = merge(local.common_tags, {
    Name = "${local.iam_role_name}-${var.iam_custom_policies[count.index].name}"
  })
}

# Attach Custom IAM Policies
resource "aws_iam_role_policy_attachment" "custom_policies" {
  count      = var.create_iam_role ? length(var.iam_custom_policies) : 0
  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.custom_policies[count.index].arn
}

# Key Pair (optional)
resource "aws_key_pair" "this" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = local.key_pair_name
  public_key = var.key_pair_public_key

  tags = merge(local.common_tags, {
    Name = local.key_pair_name
  })
}

# Additional EBS Volumes
resource "aws_ebs_volume" "additional" {
  count             = length(var.additional_volumes)
  availability_zone = data.aws_subnet.selected.availability_zone
  size              = var.additional_volumes[count.index].size
  type              = var.additional_volumes[count.index].type
  encrypted         = var.additional_volumes[count.index].encrypted

  tags = merge(local.common_tags, {
    Name = "${local.instance_name}-volume-${count.index + 1}"
  })
}

# Data source for subnet information
data "aws_subnet" "selected" {
  id = var.subnet_id
}

# EC2 Instance
resource "aws_instance" "this" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux[0].id
  instance_type = var.instance_type
  subnet_id     = var.subnet_id

  # Security Groups
  vpc_security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.existing_security_group_ids

  # IAM
  iam_instance_profile = var.create_iam_role ? aws_iam_instance_profile.this[0].name : var.existing_iam_instance_profile

  # Key Pair
  key_name = var.create_key_pair ? aws_key_pair.this[0].key_name : var.existing_key_pair_name

  # Network
  associate_public_ip_address = var.associate_public_ip_address

  # User Data
  user_data = var.user_data

  # Monitoring
  monitoring = var.enable_detailed_monitoring

  # Root Volume
  root_block_device {
    volume_size = var.root_volume_size
    volume_type = var.root_volume_type
    encrypted   = var.root_volume_encrypted

    tags = merge(local.common_tags, {
      Name = "${local.instance_name}-root-volume"
    })
  }

  tags = merge(local.common_tags, {
    Name = local.instance_name
  })

  # Lifecycle management
  lifecycle {
    create_before_destroy = true
  }
}

# Attach Additional Volumes
resource "aws_volume_attachment" "additional" {
  count       = length(var.additional_volumes)
  device_name = var.additional_volumes[count.index].device_name
  volume_id   = aws_ebs_volume.additional[count.index].id
  instance_id = aws_instance.this.id
}
