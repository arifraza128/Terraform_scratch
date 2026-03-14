provider "aws" {
  region = "ap-south-1"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "arif-devops-terraform-bucket-12345"

  tags = {
    Name        = "ArifTerraformBucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "arif-devops-terraform-bucket-12345"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}
