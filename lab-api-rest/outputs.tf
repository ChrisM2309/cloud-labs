output "api_url" {
  # SALIDA PRINCIPAL
  # URL publica del endpoint GET /hello.
  description = "URL publica de la API"
  value       = "https://${aws_api_gateway_rest_api.hello_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev/hello"
}

output "saludar_url" {
  # SALIDA SECUNDARIA
  # URL publica del endpoint POST /saludar.
  description = "URL publica del endpoint saludar"
  value       = "https://${aws_api_gateway_rest_api.hello_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev/saludar"
}
