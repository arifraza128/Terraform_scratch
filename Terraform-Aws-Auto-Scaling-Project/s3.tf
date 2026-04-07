resource "aws_s3_bucket" "my_bucket" {
  bucket = "arif-terraform-demo-bucket-12345"

  tags = {
    Name = "DemoBucket"
  }
}
