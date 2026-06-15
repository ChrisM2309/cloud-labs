# Componentes - Laboratorio 3

Este laboratorio distribuye un sitio estatico con CloudFront usando S3 como origen.

## Orden de estudio
1. `provider.tf`
2. `variables.tf`
3. `terraform.tfvars`
4. `main.tf`
5. `index.html`
6. `style.css`
7. `outputs.tf`

## Requisitos previos
Antes de correr este proyecto debes tener:
- el laboratorio 2 aplicado o un bucket S3 equivalente
- el bucket debe servir contenido web
- los archivos `index.html`, `style.css` y `logo.png` deben existir localmente

## COMPONENTE TIPO: PROVIDER AWS

- Descripcion: configuracion base de Terraform.
- Uso: conecta el despliegue con AWS.
- Necesidades: credenciales AWS.
- Requisitos: region `us-east-1` para este origen website.
- Campos a modificar: version del provider y region.
- Dependencias: todos los recursos.
- Codigo base:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
```

## COMPONENTE TIPO: VARIABLE BUCKET_NAME

- Descripcion: nombre del bucket origen.
- Uso: apunta al bucket S3 desde el cual CloudFront leerra.
- Necesidades: bucket ya creado.
- Requisitos: debe coincidir con el bucket real.
- Campos a modificar: valor de la variable en `terraform.tfvars`.
- Dependencias: objetos y distribucion.
- Codigo base:

```hcl
variable "bucket_name" {
  type = string
}
```

## COMPONENTE TIPO: TFVARS

- Descripcion: valor real de `bucket_name`.
- Uso: evita escribir el nombre del bucket en el codigo principal.
- Necesidades: la variable debe existir.
- Requisitos: nombre exacto del bucket.
- Campos a modificar: `bucket_name`.
- Dependencias: `var.bucket_name`.
- Codigo base:

```hcl
bucket_name = "laboratorio2-marroquinchristopher-2026"
```

## COMPONENTE TIPO: RECURSO AWS_S3_OBJECT INDEX

- Descripcion: pagina principal del sitio.
- Uso: sube `index.html` al bucket origen.
- Necesidades: bucket origen y archivo local.
- Requisitos: el archivo debe existir.
- Campos a modificar: `key`, `source`, `content_type`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_object" "index" {
  bucket       = var.bucket_name
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_OBJECT CSS

- Descripcion: hoja de estilos.
- Uso: sube `style.css`.
- Necesidades: bucket origen y archivo local.
- Requisitos: el archivo debe existir.
- Campos a modificar: `key`, `source`, `content_type`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_object" "css" {
  bucket       = var.bucket_name
  key          = "style.css"
  source       = "style.css"
  content_type = "text/css"
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_OBJECT LOGO

- Descripcion: imagen del sitio.
- Uso: sube `logo.png`.
- Necesidades: bucket origen y archivo local.
- Requisitos: el archivo debe existir.
- Campos a modificar: `key`, `source`, `content_type`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_object" "logo" {
  bucket       = var.bucket_name
  key          = "logo.png"
  source       = "logo.png"
  content_type = "image/png"
}
```

## COMPONENTE TIPO: RECURSO AWS_CLOUDFRONT_DISTRIBUTION

- Descripcion: distribucion CDN.
- Uso: cachea y entrega el sitio con mejor rendimiento.
- Necesidades: bucket origen con website endpoint y objetos cargados.
- Requisitos: usar `custom_origin_config` porque el website endpoint de S3 es HTTP.
- Campos a modificar: `domain_name`, `origin_protocol_policy`, `default_root_object`, `viewer_protocol_policy`.
- Dependencias: bucket, objetos y dominio de origen.
- Codigo base:

```hcl
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
```

## COMPONENTE TIPO: INDEX HTML

- Descripcion: pagina principal del sitio.
- Uso: es lo que el usuario ve.
- Necesidades: `style.css` y `logo.png`.
- Requisitos: rutas correctas en HTML.
- Campos a modificar: contenido, imagen y link CSS.
- Dependencias: objetos subidos.
- Codigo base:

```html
<!DOCTYPE html>
<html>
<head>
   <title>Laboratorio CloudFront</title>
   <link rel="stylesheet" href="style.css">
</head>
<body>

   <h1>Laboratorio 3 - CloudFront</h1>

   <p>Sitio distribuido utilizando CloudFront y Terraform.</p>

   <img src="logo.png" width="300">

</body>
</html>
```

## COMPONENTE TIPO: STYLE CSS

- Descripcion: estilos visuales.
- Uso: define apariencia del sitio.
- Necesidades: el HTML debe cargar `style.css`.
- Requisitos: rutas consistentes.
- Campos a modificar: colores, fuente y alineacion.
- Dependencias: `index.html`.
- Codigo base:

```css
body {
   font-family: Arial;
   background-color: #f5f5f5;
   text-align: center;
}

h1 {
   color: #ff9900;
}
```

## COMPONENTE TIPO: OUTPUT

- Descripcion: dominio de CloudFront.
- Uso: te da la URL publica de la CDN.
- Necesidades: distribucion creada.
- Requisitos: ninguna adicional.
- Campos a modificar: ninguno.
- Dependencias: `aws_cloudfront_distribution`.
- Codigo base:

```hcl
output "cloudfront_url" {
  value = aws_cloudfront_distribution.sitio_web.domain_name
}
```

## Resumen rapido
- S3 guarda el contenido.
- CloudFront lo distribuye.
- la variable `bucket_name` apunta al bucket existente.
- `default_root_object` define el index.
- `redirect-to-https` fuerza HTTPS.
