output "cloudfront_url" {
  # SALIDA PRINCIPAL
  # Dominio publico de la distribucion CloudFront.
  value = aws_cloudfront_distribution.sitio_web.domain_name
}
