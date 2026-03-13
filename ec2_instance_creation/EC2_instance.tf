#provider
provider "aws" {
  region = "ap-south-1"
}
#key-pair
resource "aws_key_pair" "mykey" {
  key_name   = "terraform-key"
  public_key = file("id_rsa.pub")
}
#vpc
resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
}
#subnet
resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
}
#Security-Group
resource "aws_security_group" "mySG" {
  vpc_id = aws_vpc.myvpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

  engress{
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_instance" "myinstance" {
  count = 3 #number_of_instance
  for_each = tomap({
    vm1 = t2.micro
    vm2 = t2.medium
})
  ami           = "ami-0f5ee92e2d63afc18"
  instance_type = each.value

  subnet_id = aws_subnet.mysubnet.id

  vpc_security_group_ids = [aws_security_group.mySG.id]

  key_name = aws_key_pair.mykey.key_name
  user_data=file("installnginx")
tags {
  name = each.key
}
}



provider "aws" {
  region = "ap-south-1"
}

resource "aws_instance" "my_server" {
  ami           = "unknown"
  instance_type = "unknown"
}
