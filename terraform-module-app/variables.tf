variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  description = "Environment name like dev/stage/prod"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}
