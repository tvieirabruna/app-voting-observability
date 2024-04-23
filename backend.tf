# Configure Terraform to use an S3 backend
terraform {
  backend "s3" {
    bucket = "app-voting-terraform-state-bucket"  # Unique S3 bucket for state storage
    key    = "app-voting/terraform.tfstate"  # Path to store the state in the bucket
    region = "us-east-1"  # AWS region where the S3 bucket is located
  }
}