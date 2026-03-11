resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_instance" "server" {
  ami           = "ami-12345678"
  instance_type = "t2.micro"

  depends_on = [aws_vpc.main]
}
