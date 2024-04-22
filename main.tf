# Define AWS provider and region
provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# AWS CodeCommit Repository
data "aws_codecommit_repository" "app_voting_repo" {
  repository_name = "app-voting-codecommit-repository"  # Change to your desired repo name
}

# Create an S3 bucket to store pipeline artifacts
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket = "app-voting-pipeline-artifacts"  # Change to a unique name
}

# Create IAM role for CodePipeline
resource "aws_iam_role" "codepipeline_role" {
  name = "codepipeline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "codepipeline.amazonaws.com",
      },
      Action = "sts:AssumeRole",
    }],
  })
}

resource "aws_iam_role_policy_attachment" "codepipeline_policy" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodePipeline_FullAccess"
}

# Create IAM role for CodeBuild with Terraform permissions
resource "aws_iam_role" "codebuild_role" {
  name = "codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "codebuild.amazonaws.com",
      },
      Action = "sts:AssumeRole",
    }],
  })
}

# Define a CodeBuild project to run Terraform commands
resource "aws_codebuild_project" "terraform_build" {
  name         = "app-voting-terraform-build"
  service_role = aws_iam_role.codebuild_role.arn

  artifacts {
    type = "CODEPIPELINE"  # No output artifacts from CodeBuild
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:6.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = <<-EOT
      version: 0.2
      phases:
        install:
          commands:
            - terraform init
        build:
          commands:
            - terraform plan -out=plan.tfplan
        post_build:
          commands:
            - terraform apply -auto-approve plan.tfplan
      artifacts:
        files: []
    EOT
  }
}

# Define CodePipeline
resource "aws_codepipeline" "terraform_pipeline" {
  name     = "app-voting-terraform-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    type     = "S3"
    location = aws_s3_bucket.pipeline_artifacts.bucket
  }

  stage {
    name = "Source"

    action {
      name             = "CodeCommit_Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = aws_codecommit_repository.app_voting_repo.repository_name  # Add this line
        BranchName     = "main"  # Use your desired branch
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "CodeBuild_Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform_build.name
      }
    }
  }
}