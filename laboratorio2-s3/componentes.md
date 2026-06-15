# Componentes - Laboratorio 2

Este laboratorio publica un sitio web estatico en un bucket S3.

## Orden de estudio
1. `provider.tf`
2. `main.tf`
3. `index.html`
4. `outputs.tf`

## Requisito general
Antes de correrlo debes tener:
- AWS CLI configurado
- permisos para crear bucket, policy y objetos S3
- un nombre de bucket unico

## COMPONENTE TIPO: PROVIDER AWS

- Descripcion: configuracion base de Terraform.
- Uso: conecta el proyecto con AWS.
- Necesidades: credenciales AWS.
- Requisitos: version del provider compatible.
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

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET

- Descripcion: bucket donde vive el sitio.
- Uso: almacena los archivos web.
- Necesidades: provider AWS.
- Requisitos: nombre unico global.
- Campos a modificar: `bucket`.
- Dependencias: website configuration, policy, object y outputs.
- Codigo base:

```hcl
resource "aws_s3_bucket" "sitio_web" {
  bucket = "laboratorio2-marroquinchristopher-2026"
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET_WEBSITE_CONFIGURATION

- Descripcion: habilita hosting web en S3.
- Uso: convierte el bucket en sitio web estatico.
- Necesidades: bucket creado.
- Requisitos: definir `index_document`.
- Campos a modificar: `index_document.suffix`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_bucket_website_configuration" "sitio_web" {
  bucket = aws_s3_bucket.sitio_web.id

  index_document {
    suffix = "index.html"
  }
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET_PUBLIC_ACCESS_BLOCK

- Descripcion: controla el acceso publico del bucket.
- Uso: abre el bucket para servir el sitio.
- Necesidades: bucket creado.
- Requisitos: desactivar bloqueos cuando quieras publicarlo.
- Campos a modificar: los flags de bloqueo.
- Dependencias: bucket y policy.
- Codigo base:

```hcl
resource "aws_s3_bucket_public_access_block" "sitio_web" {
  bucket = aws_s3_bucket.sitio_web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET_POLICY

- Descripcion: policy publica del bucket.
- Uso: permite `s3:GetObject` sobre los archivos web.
- Necesidades: bucket creado y access block compatible.
- Requisitos: `Principal = "*"`.
- Campos a modificar: `Principal`, `Action`, `Resource`.
- Dependencias: bucket y access block.
- Codigo base:

```hcl
resource "aws_s3_bucket_policy" "public_policy" {
  bucket = aws_s3_bucket.sitio_web.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.sitio_web.arn}/*"]
      }
    ]
  })
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_OBJECT

- Descripcion: objeto index dentro del bucket.
- Uso: sube el archivo principal del sitio.
- Necesidades: bucket y permisos listos.
- Requisitos: el archivo local `index.html` debe existir.
- Campos a modificar: `key`, `source`, `content_type`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.sitio_web.bucket
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}
```

## COMPONENTE TIPO: INDEX HTML

- Descripcion: contenido visible del sitio.
- Uso: muestra la pagina al usuario final.
- Necesidades: objeto cargado en S3.
- Requisitos: mantenerlo simple y legible.
- Campos a modificar: texto HTML.
- Dependencias: `aws_s3_object.index`.
- Codigo base:

```html
<!DOCTYPE html>
<html>
<head>
   <title>Laboratorio 2</title>
</head>
<body>
   <h1>Sitio Web Desplegado con Terraform</h1>
   <p>Laboratorio completado correctamente.</p>
</body>
</html>
```

## COMPONENTE TIPO: OUTPUT

- Descripcion: salida del website endpoint.
- Uso: te da la URL publica del sitio.
- Necesidades: website configuration aplicada.
- Requisitos: ninguno extra.
- Campos a modificar: `value`.
- Dependencias: `aws_s3_bucket_website_configuration`.
- Codigo base:

```hcl
output "website_url" {
  value = aws_s3_bucket_website_configuration.sitio_web.website_endpoint
}
```

## Resumen rapido
- bucket + website configuration = hosting web.
- access block y policy definen si el sitio es publico.
- `aws_s3_object` sube el HTML al bucket.
- el output te muestra la URL final.
