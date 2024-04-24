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
}

# Attach S3 read/write policy to the IAM role
resource "aws_iam_role_policy_attachment" "ec2_s3_policy_attachment" {
  role       = aws_iam_role.ec2_s3_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess" 
}

# Security group allowing SSH
resource "aws_security_group" "ssh_access" {
  name        = "ssh-access"
  description = "Allow SSH and HTTP access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Be careful with this. Consider limiting it to your IP or a range.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create a key pair in Terraform
resource "aws_key_pair" "key_pair" {
  key_name   = "app-voting-pair-key"       
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDFILiJewkKGG/sxMPzs9Cd0EHqJhhKnNb80iBQp6nuQB4VqgvScBiJcvMpuyl2ii7+b8VEjlOW+i+COrbAqUpQkXsiQLgCUNhiUGCvzXha6cCdxFB091/ZNI2YmEaYdHyeAoj73/ntuw5IQRCnalaHkb5gJnvDeEGJZTgdYoF+/hcX4oQAwvOIMXdc0rl0OyirNzux9Zb1jCT5mTF8q/iXlS1mDHK2lVoobqLC4qK8wrCV8m+R7G1MmyzlkHv0M7cWzu1hEGZ2riNTNIZlqgoodch6Xc2jjmQ4vfRvdhO9mIUzQH2+iBKReNEqQwxBZ1z7lRMAIwZRhJXNdUtLw8FCHdhQHkR5Tmt6PJZZ5qwQz0GINHRwesjc478pc2StKp1bsOKM7/zxyssIP+wdZgqqTI0bvxB4rSuAkxKkRfcM56JrskBOTjKybFTgJWJXaTfMEMLBIG9i7p44TV+AlVRuaAtA4auZIF/W9FUn172BUiVn0JvoFQMfxhr0/pfH6M83BgmA8sZBJVJ4DejXSKNnZqE+zwXviqOKBbGFfsKWlYX72vK7z71cciVta3wyHeGLsKouAD7iFNFt7JmZog6ZxmiiVQqLNfwBURYGrzoVLNf86j+aKQ6O5TwTcaKQh7laeaM0Tx7dTN+14LERzMtj9dFJGryFMh1dAPduar+jew== bruna@Calcifer"
}

# EC2 instance with Docker and GitHub repo cloned
resource "aws_instance" "docker_instance" {
  ami           = "ami-04e5276ebb8451442"  # Ubuntu 20.04 LTS; change if needed
  instance_type = "t2.micro"  # Adjust as needed
  key_name      = aws_key_pair.key_pair.key_name  # Your SSH key pair
  security_groups = [aws_security_group.ssh_access.name]  # Security group setup

  # Give the instance a name using tags
  tags = {
    Name = "app_voting_ec2" 
  }

  user_data = <<-EOF
    #!/bin/bash
    sudo apt-get update
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    # Clone the GitHub repository
    sudo apt-get install -y git
    cd /home/ubuntu
    git clone https://github.com/tvieirabruna/app-voting-observability.git 
  EOF
}