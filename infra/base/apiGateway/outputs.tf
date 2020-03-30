output "api_gateway_id" {
  value = aws_api_gateway_rest_api.swagger_api.id
}

output "api_gateway_rest_api_execution_arn" {
  value = aws_api_gateway_rest_api.swagger_api.execution_arn
}
