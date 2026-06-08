// RECURSO TIPO: AWS_S3_BUCKET
// Crea el bucket que almacenara el sitio web estatico.
resource "aws_s3_bucket" "sitio_web" {
  bucket = "laboratorio2-marroquinchristopher-2026"
}

// RECURSO TIPO: AWS_S3_BUCKET_WEBSITE_CONFIGURATION
// Habilita el hosting estatico del bucket y define el index principal.
resource "aws_s3_bucket_website_configuration" "sitio_web" {
  bucket = aws_s3_bucket.sitio_web.id

  index_document {
    suffix = "index.html"
  }
}

// RECURSO TIPO: AWS_S3_BUCKET_PUBLIC_ACCESS_BLOCK
// Desactiva los bloqueos de acceso publico para poder servir el sitio web.
resource "aws_s3_bucket_public_access_block" "sitio_web" {
  bucket = aws_s3_bucket.sitio_web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

// RECURSO TIPO: AWS_S3_BUCKET_POLICY
// Politica que permite lectura publica sobre los objetos del bucket.
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.sitio_web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.sitio_web.arn}/*"
        ]
      }
    ]
  })
}

// RECURSO TIPO: AWS_S3_OBJECT
// Sube el archivo index.html al bucket como objeto publico del sitio.
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.sitio_web.bucket
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}
