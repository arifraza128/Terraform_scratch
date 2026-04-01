provider "aws" {
  region = var.region
}

resource "aws_ecr_repository" "my_repo" {
  name                 = var.repo_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "Arif ECR Repo"
    Environment = "Dev"
  }
}
