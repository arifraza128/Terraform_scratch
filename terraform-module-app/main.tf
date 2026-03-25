module "dev_infra" {
  source              = "./infra-app"
  env                 = "dev"
  instance_type       = "t2.micro"
  ami_id              = "ami-0c02fb55956c7d316"
  bucket_name         = "my-dev-custom-module-bucket-123456"
  dynamodb_table_name = "dev-app-table"
}

module "stage_infra" {
  source              = "./infra-app"
  env                 = "stage"
  instance_type       = "t2.small"
  ami_id              = "ami-0c02fb55956c7d316"
  bucket_name         = "my-stage-custom-module-bucket-123456"
  dynamodb_table_name = "stage-app-table"
}

module "prod_infra" {
  source              = "./infra-app"
  env                 = "prod"
  instance_type       = "t2.medium"
  ami_id              = "ami-0c02fb55956c7d316"
  bucket_name         = "my-prod-custom-module-bucket-123456"
  dynamodb_table_name = "prod-app-table"
}
