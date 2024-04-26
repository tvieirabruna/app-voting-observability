# Define AWS provider and region
provider "aws" {
  region = "us-east-1" 
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
resource "aws_security_group" "web_access" {
  name        = "web-access"
  description = "Allow SSH, HTTP, and HTTPS access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow SSH from anywhere
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTP from anywhere
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS from anywhere
  }

  ingress {
    from_port   = 3010
    to_port     = 3010
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }
}

# EC2 instance with Docker and GitHub repo cloned
resource "aws_instance" "docker_instance" {
  ami           = "ami-080e1f13689e07408" 
  instance_type = "t3.medium" 
  key_name      = "app-voting-pair-key"  # SSH key pair already created in AWS
  security_groups = [aws_security_group.web_access.name]  # Security group setup

  # Give the instance a name using tags
  tags = {
    Name = "app_voting_ec2" 
  }

  user_data = "${file("docker_github_script.sh")}"
}

# S3 bucket to store snapshot links
resource "aws_s3_bucket" "grafana_snapshots" {
  bucket = "grafana-snapshots-bucket"  # Change to your S3 bucket name
}

# IAM role for Lambda with necessary permissions
resource "aws_iam_role" "lambda_role" {
  name = "LambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        },
        Action = "sts:AssumeRole",
      },
    ],
  })
}

# Attach policies to the Lambda role for S3 access and CloudWatch logging
resource "aws_iam_policy" "lambda_policy" {
  name   = "LambdaPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "arn:aws:logs:*:*:*",
      },
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject"],
        Resource = "arn:aws:s3:::${aws_s3_bucket.grafana_snapshots.id}/*",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda function that creates Grafana snapshots and stores the link in S3
resource "aws_lambda_function" "grafana_snapshot_lambda" {
  function_name = "GrafanaSnapshotLambda"
  runtime       = "python3.9"  # Change to your desired runtime
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  # Lambda deployment package (zip file with your Lambda code)
  filename      = "lambda_function.zip"
  source_code_hash = filebase64sha256("lambda_function.zip")

  # Environment variables for Grafana URL, S3 bucket, and Grafana credentials
  environment {
    variables = {
      GRAFANA_URL    = "http://localhost:3010",  # Your Grafana instance URL
      GRAFANA_USER   = "adatech",  # Grafana username
      GRAFANA_PASSWORD = "adatech@2233",  # Grafana password
      S3_BUCKET      = aws_s3_bucket.grafana_snapshots.id,
    }
  }
}

# Schedule the Lambda function to run every 5 minutes
resource "aws_cloudwatch_event_rule" "every_five_minutes" {
  name               = "EveryFiveMinutes"
  schedule_expression = "rate(5 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_five_minutes.name
  target_id = "GrafanaSnapshotLambda"
  arn       = aws_lambda_function.grafana_snapshot_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.grafana_snapshot_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_five_minutes.arn
}