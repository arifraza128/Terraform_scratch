resource "aws_s3_bucket" "bucket" {
  for_each = {
    dev  = "dev-bucket"
    test = "test-bucket"
    prod = "prod-bucket"
  }

  bucket = each.value
}
