# AWS CodeCommit Repository
resource "aws_codecommit_repository" "app_voting_repo" {
  repository_name = "app-voting-codecommit-repository"  # Change to your desired repo name
  description     = "Repository for App Voting project."
}

# Output the repository's clone URL for HTTPS
output "repository_clone_url_https" {
  value = aws_codecommit_repository.app_voting_repo.clone_url_http
}