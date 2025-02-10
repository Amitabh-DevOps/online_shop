resource "aws_s3_bucket" "terraform_aws_s3_bucket" {
  count  = var.create_backend ? 1 : 0
  bucket = var.aws_s3_bucket_name

  tags = {
    Name = var.aws_s3_bucket_name
  }
      
  lifecycle {
    # prevent_destroy = true
    ignore_changes = [tags]
  }
}

resource "aws_dynamodb_table" "terraform_aws_db" {
  count        = var.create_backend ? 1 : 0
  name         = var.aws_dynamodb_table_name
  billing_mode = var.aws_db_billing_mode
  hash_key     = var.aws_db_hashkey

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = var.aws_dynamodb_table_name
  }

  lifecycle {
    # prevent_destroy = true
    ignore_changes = [tags]
  }
}
