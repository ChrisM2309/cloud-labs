output "clientes_url" {
  # SALIDA PRINCIPAL
  # Endpoint publico del recurso POST /clientes.
  value = "${aws_api_gateway_stage.dev.invoke_url}/clientes"
}

output "transferencias_url" {
  # SALIDA SECUNDARIA
  # Endpoint publico del recurso POST /transferencias.
  value = "${aws_api_gateway_stage.dev.invoke_url}/transferencias"
}
