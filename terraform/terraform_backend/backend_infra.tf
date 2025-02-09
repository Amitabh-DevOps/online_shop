resource "aws_s3_bucket" "terraform_aws_s3_bucket" {
    bucket = var.aws_s3_bucket_name

    tags = {
        Name = var.aws_s3_bucket_name
    }
}

resource "aws_dynamodb_table" "terraform_aws_db" {
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
}