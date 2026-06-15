// RECURSO TIPO: AWS_S3_BUCKET
// Crea el bucket base del laboratorio 1.
// Se usa bucket_prefix para que AWS complete un nombre unico.
resource "aws_s3_bucket" "laboratorio1" {
  bucket_prefix = var.bucket_prefix
}

// RECURSO TIPO: AWS_S3_BUCKET_PUBLIC_ACCESS_BLOCK
// Bloquea el acceso publico al bucket para mantenerlo privado.
resource "aws_s3_bucket_public_access_block" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

// RECURSO TIPO: AWS_S3_BUCKET_VERSIONING
// Habilita versionado para conservar cambios de objetos.
resource "aws_s3_bucket_versioning" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  versioning_configuration {
    status = "Enabled"
  }
}

// RECURSO TIPO: AWS_S3_BUCKET_SERVER_SIDE_ENCRYPTION_CONFIGURATION
// Habilita cifrado del lado del servidor con AES256.
resource "aws_s3_bucket_server_side_encryption_configuration" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
