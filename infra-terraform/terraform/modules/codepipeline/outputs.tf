# ===================================
# CodePipeline Outputs
# ===================================

output "frontend_pipeline_arn" {
  description = "ARN of the frontend CodePipeline"
  value       = var.create_frontend_pipeline ? aws_codepipeline.frontend[0].arn : null
}

output "frontend_pipeline_name" {
  description = "Name of the frontend CodePipeline"
  value       = var.create_frontend_pipeline ? aws_codepipeline.frontend[0].name : null
}

output "api_pipeline_arn" {
  description = "ARN of the API CodePipeline"
  value       = var.create_api_pipeline ? aws_codepipeline.api[0].arn : null
}

output "api_pipeline_name" {
  description = "Name of the API CodePipeline"
  value       = var.create_api_pipeline ? aws_codepipeline.api[0].name : null
}

output "models_pipeline_arn" {
  description = "ARN of the models CodePipeline"
  value       = var.create_models_pipeline ? aws_codepipeline.models[0].arn : null
}

output "models_pipeline_name" {
  description = "Name of the models CodePipeline"
  value       = var.create_models_pipeline ? aws_codepipeline.models[0].name : null
}

output "keycloak_pipeline_arn" {
  description = "ARN of the Keycloak CodePipeline"
  value       = var.create_keycloak_pipeline ? aws_codepipeline.keycloak[0].arn : null
}

output "keycloak_pipeline_name" {
  description = "Name of the Keycloak CodePipeline"
  value       = var.create_keycloak_pipeline ? aws_codepipeline.keycloak[0].name : null
}

# ===================================
# CodeBuild Outputs
# ===================================

output "frontend_build_project_arn" {
  description = "ARN of the frontend CodeBuild project"
  value       = var.create_frontend_pipeline ? aws_codebuild_project.frontend[0].arn : null
}

output "frontend_build_project_name" {
  description = "Name of the frontend CodeBuild project"
  value       = var.create_frontend_pipeline ? aws_codebuild_project.frontend[0].name : null
}

output "api_build_project_arn" {
  description = "ARN of the API CodeBuild project"
  value       = var.create_api_pipeline ? aws_codebuild_project.api[0].arn : null
}

output "api_build_project_name" {
  description = "Name of the API CodeBuild project"
  value       = var.create_api_pipeline ? aws_codebuild_project.api[0].name : null
}

output "models_build_project_arn" {
  description = "ARN of the models CodeBuild project"
  value       = var.create_models_pipeline ? aws_codebuild_project.models[0].arn : null
}

output "models_build_project_name" {
  description = "Name of the models CodeBuild project"
  value       = var.create_models_pipeline ? aws_codebuild_project.models[0].name : null
}

output "keycloak_build_project_arn" {
  description = "ARN of the Keycloak CodeBuild project"
  value       = var.create_keycloak_pipeline ? aws_codebuild_project.keycloak[0].arn : null
}

output "keycloak_build_project_name" {
  description = "Name of the Keycloak CodeBuild project"
  value       = var.create_keycloak_pipeline ? aws_codebuild_project.keycloak[0].name : null
}

output "kainam_platform_api_pipeline_arn" {
  description = "ARN of the Kainam Platform API CodePipeline"
  value       = var.create_kainam_platform_api_pipeline ? aws_codepipeline.kainam_platform_api[0].arn : null
}

output "kainam_platform_api_pipeline_name" {
  description = "Name of the Kainam Platform API CodePipeline"
  value       = var.create_kainam_platform_api_pipeline ? aws_codepipeline.kainam_platform_api[0].name : null
}

output "kainam_platform_frontend_pipeline_arn" {
  description = "ARN of the Kainam Platform frontend CodePipeline"
  value       = var.create_kainam_platform_frontend_pipeline ? aws_codepipeline.kainam_platform_frontend[0].arn : null
}

output "kainam_platform_frontend_pipeline_name" {
  description = "Name of the Kainam Platform frontend CodePipeline"
  value       = var.create_kainam_platform_frontend_pipeline ? aws_codepipeline.kainam_platform_frontend[0].name : null
}

output "kainam_platform_api_build_project_arn" {
  description = "ARN of the Kainam Platform API CodeBuild project"
  value       = var.create_kainam_platform_api_pipeline ? aws_codebuild_project.kainam_platform_api[0].arn : null
}

output "kainam_platform_api_build_project_name" {
  description = "Name of the Kainam Platform API CodeBuild project"
  value       = var.create_kainam_platform_api_pipeline ? aws_codebuild_project.kainam_platform_api[0].name : null
}

output "kainam_platform_frontend_build_project_arn" {
  description = "ARN of the Kainam Platform frontend CodeBuild project"
  value       = var.create_kainam_platform_frontend_pipeline ? aws_codebuild_project.kainam_platform_frontend[0].arn : null
}

output "kainam_platform_frontend_build_project_name" {
  description = "Name of the Kainam Platform frontend CodeBuild project"
  value       = var.create_kainam_platform_frontend_pipeline ? aws_codebuild_project.kainam_platform_frontend[0].name : null
}

# ===================================
# IAM Outputs
# ===================================

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = aws_iam_role.codepipeline_role.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = aws_iam_role.codebuild_role.arn
}

# ===================================
# S3 Outputs
# ===================================

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.codepipeline_artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for pipeline artifacts"
  value       = aws_s3_bucket.codepipeline_artifacts.arn
}

# ===================================
# Summary Output
# ===================================

output "codepipeline_summary" {
  description = "Summary of all CodePipeline resources"
  value = {
    pipelines = {
      frontend = var.create_frontend_pipeline ? {
        name = aws_codepipeline.frontend[0].name
        arn  = aws_codepipeline.frontend[0].arn
      } : null
      api = var.create_api_pipeline ? {
        name = aws_codepipeline.api[0].name
        arn  = aws_codepipeline.api[0].arn
      } : null
      models = var.create_models_pipeline ? {
        name = aws_codepipeline.models[0].name
        arn  = aws_codepipeline.models[0].arn
      } : null
      keycloak = var.create_keycloak_pipeline ? {
        name = aws_codepipeline.keycloak[0].name
        arn  = aws_codepipeline.keycloak[0].arn
      } : null
      kainam_platform_api = var.create_kainam_platform_api_pipeline ? {
        name = aws_codepipeline.kainam_platform_api[0].name
        arn  = aws_codepipeline.kainam_platform_api[0].arn
      } : null
      kainam_platform_frontend = var.create_kainam_platform_frontend_pipeline ? {
        name = aws_codepipeline.kainam_platform_frontend[0].name
        arn  = aws_codepipeline.kainam_platform_frontend[0].arn
      } : null
    }
    build_projects = {
      frontend = var.create_frontend_pipeline ? {
        name = aws_codebuild_project.frontend[0].name
        arn  = aws_codebuild_project.frontend[0].arn
      } : null
      api = var.create_api_pipeline ? {
        name = aws_codebuild_project.api[0].name
        arn  = aws_codebuild_project.api[0].arn
      } : null
      models = var.create_models_pipeline ? {
        name = aws_codebuild_project.models[0].name
        arn  = aws_codebuild_project.models[0].arn
      } : null
      keycloak = var.create_keycloak_pipeline ? {
        name = aws_codebuild_project.keycloak[0].name
        arn  = aws_codebuild_project.keycloak[0].arn
      } : null
      kainam_platform_api = var.create_kainam_platform_api_pipeline ? {
        name = aws_codebuild_project.kainam_platform_api[0].name
        arn  = aws_codebuild_project.kainam_platform_api[0].arn
      } : null
      kainam_platform_frontend = var.create_kainam_platform_frontend_pipeline ? {
        name = aws_codebuild_project.kainam_platform_frontend[0].name
        arn  = aws_codebuild_project.kainam_platform_frontend[0].arn
      } : null
    }
    iam_roles = {
      codepipeline_role_arn = aws_iam_role.codepipeline_role.arn
      codebuild_role_arn    = aws_iam_role.codebuild_role.arn
    }
    artifacts_bucket = {
      name = aws_s3_bucket.codepipeline_artifacts.bucket
      arn  = aws_s3_bucket.codepipeline_artifacts.arn
    }
  }
}
