output "api_gateway_url" {
  description = "URL for the API Gateway webhook endpoint"
  value       = "${aws_apigatewayv2_api.webhook.api_endpoint}/webhook"
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.bot.function_name
}

output "lambda_function_arn" {
  description = "ARN of the deployed Lambda function"
  value       = aws_lambda_function.bot.arn
}
