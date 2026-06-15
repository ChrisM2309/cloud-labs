output "bucket_name" {
  # SALIDA PRINCIPAL
  # Nombre final del bucket generado por AWS.
  value = aws_s3_bucket.laboratorio1.bucket
}

output "bucket_arn" {
  # SALIDA SECUNDARIA
  # ARN del bucket para usarlo en otras configuraciones.
  value = aws_s3_bucket.laboratorio1.arn
}
