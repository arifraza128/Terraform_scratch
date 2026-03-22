provider "aws" {
  region = "ap-south-1"
}

# S3 Bucket for application code
resource "aws_s3_bucket" "app_bucket" {
  bucket = "arif-beanstalk-app-bucket-12345"
}

# Upload application file
resource "aws_s3_object" "app" {
  bucket = aws_s3_bucket.app_bucket.id
  key    = "app.zip"
  source = "app.zip"
}

# Elastic Beanstalk Application
resource "aws_elastic_beanstalk_application" "app" {
  name        = "arif-app"
  description = "Elastic Beanstalk App"
}

# Application Version
resource "aws_elastic_beanstalk_application_version" "version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.app_bucket.id
  key         = aws_s3_object.app.key
}

# Environment
resource "aws_elastic_beanstalk_environment" "env" {
  name                = "arif-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.6 running Node.js 18"

  version_label = aws_elastic_beanstalk_application_version.version.name

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}
