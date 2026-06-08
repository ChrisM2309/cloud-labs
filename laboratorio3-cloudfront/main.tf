// RECURSO TIPO: AWS_S3_OBJECT
// Sube el archivo HTML principal al bucket origen.
resource "aws_s3_object" "index" {
  bucket       = var.bucket_name
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}

// RECURSO TIPO: AWS_S3_OBJECT
// Sube la hoja de estilos que usara el sitio.
resource "aws_s3_object" "css" {
  bucket       = var.bucket_name
  key          = "style.css"
  source       = "style.css"
  content_type = "text/css"
}

// RECURSO TIPO: AWS_S3_OBJECT
// Sube la imagen logo para que el sitio tenga un elemento visual.
resource "aws_s3_object" "logo" {
  bucket       = var.bucket_name
  key          = "logo.png"
  source       = "logo.png"
  content_type = "image/png"
}

// RECURSO TIPO: AWS_CLOUDFRONT_DISTRIBUTION
// Distribucion que entrega el contenido de S3 con mejor rendimiento global.
resource "aws_cloudfront_distribution" "sitio_web" {
  origin {
    domain_name = "${var.bucket_name}.s3-website-us-east-1.amazonaws.com"
    origin_id   = "s3-origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id  = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
