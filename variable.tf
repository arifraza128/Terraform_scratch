variable "instance_type" {
  default = "t2.micro"
}

resource "aws_instance" "example" {
  ami           = "ami-0abcdef1234567890"
  instance_type = var.instance_type
}
