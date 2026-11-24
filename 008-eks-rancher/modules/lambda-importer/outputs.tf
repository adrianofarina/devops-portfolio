output "lambda_function_name" {
  description = "Name of the deployed Lambda importer function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda importer function"
  value       = aws_lambda_function.this.arn
}

output "lambda_role_arn" {
  description = "ARN of the IAM execution role assumed by the Lambda"
  value       = aws_iam_role.this.arn
}
