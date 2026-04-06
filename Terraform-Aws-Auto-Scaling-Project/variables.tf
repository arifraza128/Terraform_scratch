variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "EC2 Key Pair"
}

variable "subnet_id" {
  description = "Subnet ID"
}
