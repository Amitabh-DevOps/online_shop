# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  count         = var.create_backend ? 1 : 0
  bucket        = var.aws_s3_bucket_name
  force_destroy = true

  tags = {
    Name        = var.aws_s3_bucket_name
    Environment = "production"
    Purpose     = "terraform-state"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.create_backend ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.create_backend ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.create_backend ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  count        = var.create_backend ? 1 : 0
  name         = var.aws_dynamodb_table_name
  billing_mode = var.aws_db_billing_mode
  hash_key     = var.aws_db_hashkey

  attribute {
    name = var.aws_db_hashkey
    type = "S"
  }

  tags = {
    Name        = var.aws_dynamodb_table_name
    Environment = "production"
    Purpose     = "terraform-state-locking"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [tags]
  }
}
