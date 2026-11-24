output "lambda_function_name" {
  description = "Deployed Lambda function name"
  value       = module.lambda_importer.lambda_function_name
}

output "lambda_function_arn" {
  description = "Deployed Lambda function ARN"
  value       = module.lambda_importer.lambda_function_arn
}

output "invoke_command" {
  description = "Command to trigger the Lambda and import workload-eks into Rancher"
  value       = "aws lambda invoke --region ${var.aws_region} --function-name ${module.lambda_importer.lambda_function_name} response.json && cat response.json"
}
