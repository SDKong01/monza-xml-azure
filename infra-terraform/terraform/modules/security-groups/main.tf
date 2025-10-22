# Local values for consistent resource naming and tagging
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  common_tags = merge(
    var.common_tags,
    {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "security-groups"
    }
  )
}

# ALB Security Group
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer - allows public HTTPS traffic"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-alb-sg"
      Tier = "Load Balancer"
    }
  )
}

# ALB Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS traffic from internet"

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  tags = {
    Name = "alb-https-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow traffic to web tier security group"

  referenced_security_group_id = aws_security_group.web.id
  ip_protocol                  = "-1"

  tags = {
    Name = "alb-to-web-egress"
  }
}

# Web Tier Security Group
resource "aws_security_group" "web" {
  name        = "${local.name_prefix}-web-sg"
  description = "Security group for web tier (EC2 instances) - allows traffic from ALB and SSH from trusted sources"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-web-sg"
      Tier = "Web/Application"
    }
  )
}

# Web Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all traffic from ALB security group"

  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "-1"

  tags = {
    Name = "web-from-alb-ingress"
  }
}

# SSH access rule - only if trusted IP ranges are provided
resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  count = length(var.trusted_ip_ranges) > 0 ? length(var.trusted_ip_ranges) : 0

  security_group_id = aws_security_group.web.id
  description       = "Allow SSH access from trusted IP range ${count.index + 1}"

  cidr_ipv4   = var.trusted_ip_ranges[count.index]
  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"

  tags = {
    Name = "web-ssh-ingress-${count.index + 1}"
  }
}

resource "aws_vpc_security_group_egress_rule" "web_all_outbound" {
  security_group_id = aws_security_group.web.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "web-all-outbound-egress"
  }
}

# Database Security Group
resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Security group for database tier - allows traffic only from web tier"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-db-sg"
      Tier = "Database"
    }
  )
}

# Database Security Group Rules
resource "aws_vpc_security_group_ingress_rule" "db_from_web" {
  security_group_id = aws_security_group.db.id
  description       = "Allow PostgreSQL access from web tier security group"

  referenced_security_group_id = aws_security_group.web.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"

  tags = {
    Name = "db-from-web-ingress"
  }
}

resource "aws_vpc_security_group_egress_rule" "db_all_outbound" {
  security_group_id = aws_security_group.db.id
  description       = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"

  tags = {
    Name = "db-all-outbound-egress"
  }
}
