# Define AWS provider and region
provider "aws" {
  region = "us-east-1"  # Change to your preferred region
}

# AWS CodeCommit Repository
resource "aws_codecommit_repository" "app_voting_repo" {
  repository_name = "app-voting-codecommit-repository"
  description     = "Repository for App Voting project"
}

# Create an S3 bucket
resource "aws_s3_bucket" "s3_report_bucket" {
  bucket = "app-voting-report-bucket" 
}

# Create IAM role for EC2 with S3 permissions
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }],
  })
}

# Create an IAM Instance Profile and attach the role
resource "aws_iam_instance_profile" "ec2_s3_instance_profile" {
  name = "ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_role.name  # Associate the role with the instance profile

  lifecycle {
    ignore_changes = [name]  # Prevent Terraform from recreating if the name already exists
  }
}

# Attach S3 read/write policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # Full access; tailor as needed
}

# Create an EC2 instance and use the correct instance profile
resource "aws_instance" "docker_instance" {
  ami           = "ami-04e5276ebb8451442"  # Change to a valid AMI ID
  instance_type = "t2.micro"  # Adjust as needed
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_instance_profile.name

  # Give the instance a name using tags
  tags = {
    Name = "app_voting_ec2" 
  }

  # Optional: Security group allowing SSH and HTTP
  security_groups = ["default"]  # Adjust as needed

  # User-data script to install AWS CLI and test S3 access
  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y awscli
    aws s3 ls s3://${aws_s3_bucket.s3_report_bucket.bucket}
  EOF
}

# Output the public IP of the EC2 instance
output "ec2_public_ip" {
  value = aws_instance.docker_instance.public_ip
}

# Output the S3 bucket name
output "s3_bucket_name" {
  value = aws_s3_bucket.s3_report_bucket.bucket
}