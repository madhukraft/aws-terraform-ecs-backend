output "state_bucket" {
  value       = aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket for Terraform state"
}

output "state_bucket_arn" {
  value       = aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket for Terraform state"
}

output "lock_table" {
  value       = try(aws_dynamodb_table.terraform_locks[0].name, null)
  description = "Name of the DynamoDB table for state locking"
}
