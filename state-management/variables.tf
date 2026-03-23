variable "region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "ami_id" {
  description = "AMI ID for EC2"
  default     = "ami-0f5ee92e2d63afc18"  # Amazon Linux (Mumbai)
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}
