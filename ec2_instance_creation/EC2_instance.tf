#provider
provider "aws" {
  region = "ap-south-1"
}
#key-pair
resource "aws_key_pair" "mykey" {
  key_name   = "terraform-key"
  public_key = file("id_rsa.pub")
}
