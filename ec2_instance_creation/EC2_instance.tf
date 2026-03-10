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
