output "s3_bucket_name" {
  value       = var.create_backend ? aws_s3_bucket.terraform_state[0].bucket : "Not created"
  description = "The name of the S3 bucket for Terraform state."
}

output "s3_bucket_arn" {
  value       = var.create_backend ? aws_s3_bucket.terraform_state[0].arn : "Not created"
  description = "The ARN of the S3 bucket for Terraform state."
}

output "dynamodb_table_name" {
  value       = var.create_backend ? aws_dynamodb_table.terraform_locks[0].name : "Not created"
  description = "The name of the DynamoDB table for state locking."
}

output "dynamodb_table_arn" {
  value       = var.create_backend ? aws_dynamodb_table.terraform_locks[0].arn : "Not created"
  description = "The ARN of the DynamoDB table for state locking."
}

output "backend_configuration" {
  value = var.create_backend ? {
    bucket         = aws_s3_bucket.terraform_state[0].bucket
    key            = "terraform.tfstate"
    region         = var.aws_region
    dynamodb_table = aws_dynamodb_table.terraform_locks[0].name
    encrypt        = true
  } : {}
  description = "Backend configuration for Terraform state."
}
