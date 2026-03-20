variable "region" {
  default = "us-east-1"
}

variable "ami_id" {
  description = "AMI ID"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "EC2 Key Pair"
}

variable "vpc_id" {}
variable "subnet_ids" {
  type = list(string)
}
