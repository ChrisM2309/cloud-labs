output "website_url" {
  # SALIDA PRINCIPAL
  # Endpoint del hosting estatico de S3.
  value = aws_s3_bucket_website_configuration.sitio_web.website_endpoint
}
