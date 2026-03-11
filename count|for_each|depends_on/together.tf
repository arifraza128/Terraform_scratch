resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_instance" "server" {
  for_each = {
    app1 = "t2.micro"
    app2 = "t2.small"
  }

  ami           = "ami-12345678"
  instance_type = each.value

  depends_on = [aws_vpc.main]
}
