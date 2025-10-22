# ===================================
# GitHub OIDC Provider Outputs
# ===================================

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : null
}

output "github_oidc_provider_url" {
  description = "URL of the GitHub OIDC provider"
  value       = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].url : null
}

# ===================================
# GitHub Actions Role Outputs
# ===================================

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions ECR push role"
  value       = var.create_github_oidc_role ? aws_iam_role.github_actions_ecr_push[0].arn : null
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions ECR push role"
  value       = var.create_github_oidc_role ? aws_iam_role.github_actions_ecr_push[0].name : null
}

output "github_actions_role_unique_id" {
  description = "Unique ID of the GitHub Actions ECR push role"
  value       = var.create_github_oidc_role ? aws_iam_role.github_actions_ecr_push[0].unique_id : null
}

# ===================================
# App Runner Access Role Outputs
# ===================================

output "app_runner_access_role_arn" {
  description = "ARN of the App Runner access role"
  value       = var.create_app_runner_access_role ? aws_iam_role.app_runner_access[0].arn : null
}

output "app_runner_access_role_name" {
  description = "Name of the App Runner access role"
  value       = var.create_app_runner_access_role ? aws_iam_role.app_runner_access[0].name : null
}

# ===================================
# App Runner Instance Role Outputs
# ===================================

output "app_runner_instance_role_arn" {
  description = "ARN of the App Runner instance role"
  value       = var.create_app_runner_instance_role ? aws_iam_role.app_runner_instance[0].arn : null
}

output "app_runner_instance_role_name" {
  description = "Name of the App Runner instance role"
  value       = var.create_app_runner_instance_role ? aws_iam_role.app_runner_instance[0].name : null
}

# ===================================
# EC2 Instance Role Outputs
# ===================================

output "ec2_instance_role_arn" {
  description = "ARN of the EC2 instance role"
  value       = var.create_ec2_instance_role ? aws_iam_role.ec2_instance[0].arn : null
}

output "ec2_instance_role_name" {
  description = "Name of the EC2 instance role"
  value       = var.create_ec2_instance_role ? aws_iam_role.ec2_instance[0].name : null
}

output "ec2_instance_profile_arn" {
  description = "ARN of the EC2 instance profile"
  value       = var.create_ec2_instance_role ? aws_iam_instance_profile.ec2_instance[0].arn : null
}

output "ec2_instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = var.create_ec2_instance_role ? aws_iam_instance_profile.ec2_instance[0].name : null
}

# ===================================
# EC2 Worker Role Outputs
# ===================================

output "ec2_worker_role_arn" {
  description = "ARN of the EC2 worker role"
  value       = var.create_ec2_worker_role ? aws_iam_role.ec2_worker[0].arn : null
}

output "ec2_worker_role_name" {
  description = "Name of the EC2 worker role"
  value       = var.create_ec2_worker_role ? aws_iam_role.ec2_worker[0].name : null
}

output "ec2_worker_instance_profile_arn" {
  description = "ARN of the EC2 worker instance profile"
  value       = var.create_ec2_worker_role ? aws_iam_instance_profile.ec2_worker[0].arn : null
}

output "ec2_worker_instance_profile_name" {
  description = "Name of the EC2 worker instance profile"
  value       = var.create_ec2_worker_role ? aws_iam_instance_profile.ec2_worker[0].name : null
}

# ===================================
# Summary Outputs
# ===================================

output "iam_roles_summary" {
  description = "Summary of all created IAM roles"
  value = {
    github_actions_role_arn         = var.create_github_oidc_role ? aws_iam_role.github_actions_ecr_push[0].arn : null
    app_runner_access_role_arn      = var.create_app_runner_access_role ? aws_iam_role.app_runner_access[0].arn : null
    app_runner_instance_role_arn    = var.create_app_runner_instance_role ? aws_iam_role.app_runner_instance[0].arn : null
    ec2_instance_role_arn           = var.create_ec2_instance_role ? aws_iam_role.ec2_instance[0].arn : null
    ec2_instance_profile_arn        = var.create_ec2_instance_role ? aws_iam_instance_profile.ec2_instance[0].arn : null
    ec2_worker_role_arn             = var.create_ec2_worker_role ? aws_iam_role.ec2_worker[0].arn : null
    ec2_worker_instance_profile_arn = var.create_ec2_worker_role ? aws_iam_instance_profile.ec2_worker[0].arn : null
  }
}

output "github_actions_usage_instructions" {
  description = "Instructions for using the GitHub Actions role in workflows"
  value = var.create_github_oidc_role ? {
    role_arn             = aws_iam_role.github_actions_ecr_push[0].arn
    usage_example        = <<-EOT
      # Add this to your GitHub Actions workflow:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${aws_iam_role.github_actions_ecr_push[0].arn}
          role-session-name: GitHubActions-ECR-Push
          aws-region: ${data.aws_region.current.name}
      
      - name: Login to Amazon ECR
        uses: aws-actions/amazon-ecr-login@v2
        
      - name: Build and push Docker image
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
    EOT
    allowed_repositories = var.github_repositories
    allowed_branches     = var.github_branches
  } : null
}
