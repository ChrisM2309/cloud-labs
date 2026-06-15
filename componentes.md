# Componentes Terraform y apoyo

Este archivo es un catalogo practico de todos los componentes usados en los labs del repo.

Orden de estudio:
1. `laboratorio-1`
2. `laboratorio2-s3`
3. `laboratorio3-cloudfront`
4. `laboratorio4`
5. `lab-api-rest`

Formato de cada componente:
- Que es
- Para que sirve
- Que debe existir antes
- Que campos se suelen modificar
- Que otros componentes lo usan
- Codigo base

---

## LABORATORIO 1 - BASE DE ACCESO Y S3

### COMPONENTE OPERATIVO: IAM + AWS CLI + TERRAFORM

- Que es: la preparacion previa antes de escribir Terraform.
- Para que sirve: crear usuario IAM, generar access keys, configurar AWS CLI, verificar acceso a S3 y probar Terraform.
- Antes de esto: debes tener una cuenta AWS activa.
- Campos a modificar: region de AWS, nombre de usuario IAM, access keys.
- Lo usan: todos los labs siguientes.

```bash
aws configure
aws s3 ls
terraform init
terraform validate
```

### COMPONENTE TIPO: PROVIDER AWS

- Que es: la configuracion que conecta Terraform con AWS.
- Para que sirve: indica version de Terraform, provider AWS y region por defecto.
- Antes de esto: credenciales AWS configuradas.
- Campos a modificar: `required_version`, version del provider y `region`.
- Lo usan: todos los recursos del laboratorio.

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### COMPONENTE TIPO: VARIABLE AWS_REGION

- Que es: variable de region AWS.
- Para que sirve: permite cambiar la region sin editar el provider.
- Antes de esto: ninguna.
- Campos a modificar: `default`.
- Lo usan: `provider.tf` y `outputs.tf`.

```hcl
variable "aws_region" {
  description = "Region AWS donde se desplegara el laboratorio 1"
  type        = string
  default     = "us-east-1"
}
```

### COMPONENTE TIPO: VARIABLE BUCKET_PREFIX

- Que es: prefijo para generar un bucket unico.
- Para que sirve: evita conflictos de nombres globales en S3.
- Antes de esto: ninguna.
- Campos a modificar: `default`.
- Lo usan: `aws_s3_bucket.laboratorio1`.

```hcl
variable "bucket_prefix" {
  description = "Prefijo del bucket S3"
  type        = string
  default     = "laboratorio1-terraform-"
}
```

### RECURSO TIPO: AWS_S3_BUCKET

- Que es: el bucket principal del laboratorio.
- Para que sirve: guardar objetos en S3.
- Antes de esto: provider AWS y permisos correctos.
- Campos a modificar: `bucket_prefix` o `bucket`.
- Lo usan: public access block, versioning, encryption y outputs.

```hcl
resource "aws_s3_bucket" "laboratorio1" {
  bucket_prefix = var.bucket_prefix
}
```

### RECURSO TIPO: AWS_S3_BUCKET_PUBLIC_ACCESS_BLOCK

- Que es: bloquea o permite acceso publico al bucket.
- Para que sirve: mantener el bucket privado.
- Antes de esto: el bucket debe existir.
- Campos a modificar: los 4 flags de bloqueo.
- Lo usan: el bucket S3 del laboratorio.

```hcl
resource "aws_s3_bucket_public_access_block" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### RECURSO TIPO: AWS_S3_BUCKET_VERSIONING

- Que es: activa versionado en S3.
- Para que sirve: conservar versiones anteriores de objetos.
- Antes de esto: el bucket debe existir.
- Campos a modificar: `status`.
- Lo usan: el bucket principal.

```hcl
resource "aws_s3_bucket_versioning" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

### RECURSO TIPO: AWS_S3_BUCKET_SERVER_SIDE_ENCRYPTION_CONFIGURATION

- Que es: configuracion de cifrado del lado del servidor.
- Para que sirve: proteger objetos guardados en S3.
- Antes de esto: el bucket debe existir.
- Campos a modificar: algoritmo de cifrado.
- Lo usan: el bucket principal.

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

### COMPONENTE TIPO: OUTPUTS

- Que es: salidas utiles al final del deploy.
- Para que sirve: mostrar nombre y ARN del bucket.
- Antes de esto: el bucket debe existir.
- Campos a modificar: el texto de salida y el valor.
- Lo usan: tu terminal y la guia de estudio.

```hcl
output "bucket_name" {
  value = aws_s3_bucket.laboratorio1.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.laboratorio1.arn
}
```

---

## LABORATORIO 2 - SITIO WEB ESTATICO EN S3

### COMPONENTE TIPO: PROVIDER AWS

- Que es: conexion de Terraform con AWS.
- Para que sirve: definir provider y region del laboratorio.
- Antes de esto: credenciales AWS configuradas.
- Campos a modificar: version del provider y region.
- Lo usan: los recursos S3.

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

### RECURSO TIPO: AWS_S3_BUCKET

- Que es: el bucket que aloja el sitio.
- Para que sirve: almacenar el contenido estatico.
- Antes de esto: provider AWS.
- Campos a modificar: nombre del bucket.
- Lo usan: website configuration, policy, object y outputs.

```hcl
resource "aws_s3_bucket" "sitio_web" {
  bucket = "laboratorio2-marroquinchristopher-2026"
}
```

### RECURSO TIPO: AWS_S3_BUCKET_WEBSITE_CONFIGURATION

- Que es: habilitacion de hosting web en S3.
- Para que sirve: convertir el bucket en sitio web estatico.
- Antes de esto: bucket creado.
- Campos a modificar: `index_document.suffix`.
- Lo usan: el output `website_url`.

```hcl
resource "aws_s3_bucket_website_configuration" "sitio_web" {
  bucket = aws_s3_bucket.sitio_web.id

  index_document {
    suffix = "index.html"
  }
}
```

### RECURSO TIPO: AWS_S3_BUCKET_PUBLIC_ACCESS_BLOCK

- Que es: control de acceso publico del bucket.
- Para que sirve: abrir el sitio cuando sea necesario.
- Antes de esto: bucket creado.
- Campos a modificar: los flags de bloqueo.
- Lo usan: la policy publica.

```hcl
resource "aws_s3_bucket_public_access_block" "sitio_web" {
  bucket = aws_s3_bucket.sitio_web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

### RECURSO TIPO: AWS_S3_BUCKET_POLICY

- Que es: policy del bucket.
- Para que sirve: permitir lectura publica de objetos.
- Antes de esto: bucket creado y access block ajustado.
- Campos a modificar: `Principal`, `Action`, `Resource`.
- Lo usan: el acceso web de S3.

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

### RECURSO TIPO: AWS_S3_OBJECT

- Que es: un archivo dentro del bucket.
- Para que sirve: subir `index.html` al sitio.
- Antes de esto: bucket y permisos listos.
- Campos a modificar: `key`, `source`, `content_type`.
- Lo usan: la website configuration.

```hcl
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.sitio_web.bucket
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}
```

### COMPONENTE TIPO: INDEX HTML

- Que es: el contenido principal del sitio.
- Para que sirve: mostrar la pagina al visitante.
- Antes de esto: bucket y objeto index cargado.
- Campos a modificar: texto HTML.
- Lo usan: el bucket web y el navegador.

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

### COMPONENTE TIPO: OUTPUT

- Que es: salida final del sitio.
- Para que sirve: mostrar la URL del website endpoint.
- Antes de esto: website configuration aplicada.
- Campos a modificar: ninguno.
- Lo usan: tu consola.

```hcl
output "website_url" {
  value = aws_s3_bucket_website_configuration.sitio_web.website_endpoint
}
```

---

## LABORATORIO 3 - S3 + CLOUDFRONT

### COMPONENTE TIPO: PROVIDER AWS

- Que es: provider AWS para CloudFront y S3.
- Para que sirve: crear objetos y la distribucion.
- Antes de esto: credenciales AWS.
- Campos a modificar: region del provider.
- Lo usan: todos los recursos del laboratorio.

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

### COMPONENTE TIPO: VARIABLE BUCKET_NAME

- Que es: variable del bucket origen.
- Para que sirve: apuntar a un bucket ya creado.
- Antes de esto: el bucket debe existir.
- Campos a modificar: ninguna, solo valor.
- Lo usan: S3 objects y CloudFront origin.

```hcl
variable "bucket_name" {
  type = string
}
```

### COMPONENTE TIPO: TFVARS

- Que es: archivo con el valor de la variable.
- Para que sirve: separar configuracion del codigo.
- Antes de esto: la variable debe existir.
- Campos a modificar: el nombre del bucket.
- Lo usan: `var.bucket_name`.

```hcl
bucket_name = "laboratorio2-marroquinchristopher-2026"
```

### RECURSO TIPO: AWS_S3_OBJECT INDEX

- Que es: objeto index del sitio.
- Para que sirve: subir la pagina principal al bucket origen.
- Antes de esto: bucket_name valido.
- Campos a modificar: `key`, `source`, `content_type`.
- Lo usan: CloudFront como contenido origen.

```hcl
resource "aws_s3_object" "index" {
  bucket       = var.bucket_name
  key          = "index.html"
  source       = "index.html"
  content_type = "text/html"
}
```

### RECURSO TIPO: AWS_S3_OBJECT CSS

- Que es: hoja de estilos.
- Para que sirve: darle formato visual al sitio.
- Antes de esto: bucket origen.
- Campos a modificar: `key`, `source`, `content_type`.
- Lo usan: el `index.html`.

```hcl
resource "aws_s3_object" "css" {
  bucket       = var.bucket_name
  key          = "style.css"
  source       = "style.css"
  content_type = "text/css"
}
```

### RECURSO TIPO: AWS_S3_OBJECT LOGO

- Que es: imagen del sitio.
- Para que sirve: agregar contenido visual.
- Antes de esto: bucket origen.
- Campos a modificar: `key`, `source`, `content_type`.
- Lo usan: el HTML.

```hcl
resource "aws_s3_object" "logo" {
  bucket       = var.bucket_name
  key          = "logo.png"
  source       = "logo.png"
  content_type = "image/png"
}
```

### RECURSO TIPO: AWS_CLOUDFRONT_DISTRIBUTION

- Que es: la distribucion global de contenido.
- Para que sirve: cachear y servir el sitio mas rapido.
- Antes de esto: bucket origen, objetos subidos y endpoint de website de S3.
- Campos a modificar: `domain_name`, `viewer_protocol_policy`, `default_root_object`.
- Lo usan: el dominio publico de CloudFront.

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

### COMPONENTE TIPO: INDEX HTML

- Que es: pagina principal del sitio.
- Para que sirve: mostrar contenido que CloudFront distribuye.
- Antes de esto: objetos subidos al bucket.
- Campos a modificar: texto, imagen y ruta CSS.
- Lo usan: el usuario final y CloudFront.

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

### COMPONENTE TIPO: STYLE CSS

- Que es: hoja de estilos.
- Para que sirve: cambiar apariencia visual.
- Antes de esto: archivo `style.css` subido al bucket.
- Campos a modificar: fuentes, colores y layout.
- Lo usan: el `index.html`.

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

### COMPONENTE TIPO: OUTPUT

- Que es: salida de la distribucion.
- Para que sirve: mostrar el dominio publico de CloudFront.
- Antes de esto: la distribucion debe estar creada.
- Campos a modificar: ninguno.
- Lo usan: tu navegador.

```hcl
output "cloudfront_url" {
  value = aws_cloudfront_distribution.sitio_web.domain_name
}
```

---

## LABORATORIO 4 - DYNAMODB + LAMBDA + API GATEWAY

### COMPONENTE TIPO: PROVIDER AWS

- Que es: provider AWS del laboratorio.
- Para que sirve: desplegar tablas, Lambdas y API.
- Antes de esto: credenciales AWS.
- Campos a modificar: region.
- Lo usan: todos los recursos.

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
  region = var.region
}
```

### COMPONENTE TIPO: VARIABLE REGION

- Que es: region del despliegue.
- Para que sirve: controlar donde vive toda la solucion.
- Antes de esto: ninguna.
- Campos a modificar: `default`.
- Lo usan: el provider.

```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}
```

### RECURSO TIPO: AWS_DYNAMODB_TABLE CLIENTES

- Que es: tabla de clientes.
- Para que sirve: guardar clientes creados por la Lambda.
- Antes de esto: provider AWS.
- Campos a modificar: `name`, `hash_key`, atributo `id`.
- Lo usan: `crear_cliente`.

```hcl
resource "aws_dynamodb_table" "clientes" {
  name         = "clientes"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
```

### RECURSO TIPO: AWS_DYNAMODB_TABLE CUENTAS

- Que es: tabla de cuentas.
- Para que sirve: modelar cuentas dentro del sistema.
- Antes de esto: provider AWS.
- Campos a modificar: `name`, `hash_key`, atributo `cuenta_id`.
- Lo usan: futuras extensiones del sistema.

```hcl
resource "aws_dynamodb_table" "cuentas" {
  name         = "cuentas"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "cuenta_id"

  attribute {
    name = "cuenta_id"
    type = "S"
  }
}
```

### RECURSO TIPO: AWS_DYNAMODB_TABLE TRANSFERENCIAS

- Que es: tabla de transferencias.
- Para que sirve: guardar movimientos entre cuentas.
- Antes de esto: provider AWS.
- Campos a modificar: `name`, `hash_key`, atributo `transferencia_id`.
- Lo usan: `realizar_transferencia`.

```hcl
resource "aws_dynamodb_table" "transferencias" {
  name         = "transferencias"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "transferencia_id"

  attribute {
    name = "transferencia_id"
    type = "S"
  }
}
```

### RECURSO TIPO: AWS_IAM_ROLE

- Que es: rol para Lambda.
- Para que sirve: permitir que Lambda asuma permisos.
- Antes de esto: provider AWS.
- Campos a modificar: `name` y `assume_role_policy`.
- Lo usan: las dos funciones Lambda.

```hcl
resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}
```

### RECURSO TIPO: AWS_IAM_ROLE_POLICY_ATTACHMENT

- Que es: attachment de policy administrada.
- Para que sirve: permitir logs en CloudWatch.
- Antes de esto: el rol debe existir.
- Campos a modificar: `policy_arn`.
- Lo usan: las Lambdas.

```hcl
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

### RECURSO TIPO: AWS_IAM_ROLE_POLICY

- Que es: policy inline.
- Para que sirve: dar permisos a DynamoDB.
- Antes de esto: el rol debe existir.
- Campos a modificar: acciones y recursos permitidos.
- Lo usan: las Lambdas que escriben en DynamoDB.

```hcl
resource "aws_iam_role_policy" "dynamodb_policy" {
  name = "dynamodb_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["dynamodb:*"]
      Resource = "*"
    }]
  })
}
```

### RECURSO TIPO: AWS_LAMBDA_FUNCTION CREADOR_CLIENTE

- Que es: Lambda para crear clientes.
- Para que sirve: validar datos y escribir en DynamoDB.
- Antes de esto: tabla `clientes`, rol IAM y zip `lambda.zip`.
- Campos a modificar: `runtime`, `handler`, `filename`, `source_code_hash`.
- Lo usan: API Gateway y DynamoDB.

```hcl
resource "aws_lambda_function" "crear_cliente" {
  function_name = "crear_cliente"
  runtime       = "python3.11"
  handler       = "main.lambda_handler"
  filename      = "../lambdas/crear_cliente/lambda.zip"

  source_code_hash = filebase64sha256("../lambdas/crear_cliente/lambda.zip")
  role             = aws_iam_role.lambda_role.arn

  depends_on = [
    aws_dynamodb_table.clientes
  ]
}
```

### RECURSO TIPO: AWS_LAMBDA_FUNCTION REALIZAR_TRANSFERENCIA

- Que es: Lambda para registrar transferencias.
- Para que sirve: guardar movimientos en DynamoDB.
- Antes de esto: tabla `transferencias`, rol IAM y zip `lambda.zip`.
- Campos a modificar: `runtime`, `handler`, `filename`, `source_code_hash`.
- Lo usan: API Gateway y DynamoDB.

```hcl
resource "aws_lambda_function" "realizar_transferencia" {
  function_name = "realizar_transferencia"
  runtime       = "python3.11"
  handler       = "main.lambda_handler"
  filename      = "../lambdas/realizar_transferencia/lambda.zip"

  source_code_hash = filebase64sha256("../lambdas/realizar_transferencia/lambda.zip")
  role             = aws_iam_role.lambda_role.arn

  depends_on = [
    aws_dynamodb_table.transferencias
  ]
}
```

### RECURSO TIPO: AWS_API_GATEWAY_REST_API

- Que es: API principal.
- Para que sirve: recibir requests HTTP.
- Antes de esto: provider AWS.
- Campos a modificar: `name`.
- Lo usan: resources, methods e integrations.

```hcl
resource "aws_api_gateway_rest_api" "api" {
  name = "laboratorio-api"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_RESOURCE CLIENTES

- Que es: ruta `/clientes`.
- Para que sirve: exponer el endpoint de clientes.
- Antes de esto: API REST creada.
- Campos a modificar: `path_part`.
- Lo usan: method e integration.

```hcl
resource "aws_api_gateway_resource" "clientes_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "clientes"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_METHOD CLIENTES_POST

- Que es: metodo POST de la ruta.
- Para que sirve: aceptar requests para crear clientes.
- Antes de esto: resource `/clientes`.
- Campos a modificar: `http_method`, `authorization`.
- Lo usan: la integration.

```hcl
resource "aws_api_gateway_method" "clientes_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.clientes_resource.id
  http_method   = "POST"
  authorization = "NONE"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION CLIENTES

- Que es: union entre API y Lambda.
- Para que sirve: enviar el request a `crear_cliente`.
- Antes de esto: method y Lambda.
- Campos a modificar: `uri`, `type`, `integration_http_method`.
- Lo usan: API Gateway.

```hcl
resource "aws_api_gateway_integration" "clientes_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.clientes_resource.id
  http_method             = aws_api_gateway_method.clientes_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crear_cliente.invoke_arn
}
```

### RECURSO TIPO: AWS_LAMBDA_PERMISSION CLIENTES

- Que es: permiso para invocar Lambda.
- Para que sirve: permitir que API Gateway llame la funcion.
- Antes de esto: Lambda y API REST.
- Campos a modificar: `statement_id`, `source_arn`.
- Lo usan: API Gateway.

```hcl
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crear_cliente.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_RESOURCE TRANSFERENCIAS

- Que es: ruta `/transferencias`.
- Para que sirve: exponer el endpoint de transferencias.
- Antes de esto: API REST creada.
- Campos a modificar: `path_part`.
- Lo usan: method e integration.

```hcl
resource "aws_api_gateway_resource" "transferencias_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "transferencias"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_METHOD TRANSFERENCIAS_POST

- Que es: metodo POST de la ruta.
- Para que sirve: aceptar requests de transferencias.
- Antes de esto: resource `/transferencias`.
- Campos a modificar: `http_method`, `authorization`.
- Lo usan: la integration.

```hcl
resource "aws_api_gateway_method" "transferencias_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.transferencias_resource.id
  http_method   = "POST"
  authorization = "NONE"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION TRANSFERENCIAS

- Que es: union entre API y Lambda.
- Para que sirve: enviar el request a `realizar_transferencia`.
- Antes de esto: method y Lambda.
- Campos a modificar: `uri`, `type`, `integration_http_method`.
- Lo usan: API Gateway.

```hcl
resource "aws_api_gateway_integration" "transferencias_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.transferencias_resource.id
  http_method             = aws_api_gateway_method.transferencias_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.realizar_transferencia.invoke_arn
}
```

### RECURSO TIPO: AWS_LAMBDA_PERMISSION TRANSFERENCIAS

- Que es: permiso para invocar la Lambda de transferencias.
- Para que sirve: dejar que API Gateway la ejecute.
- Antes de esto: Lambda y API REST.
- Campos a modificar: `statement_id`, `source_arn`.
- Lo usan: API Gateway.

```hcl
resource "aws_lambda_permission" "transferencias_permission" {
  statement_id  = "AllowTransferenciasInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.realizar_transferencia.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_DEPLOYMENT

- Que es: deployment de la API.
- Para que sirve: publicar cambios.
- Antes de esto: integraciones creadas.
- Campos a modificar: `triggers`, `depends_on`.
- Lo usan: el stage `dev`.

```hcl
resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_integration.clientes_integration,
    aws_api_gateway_integration.transferencias_integration
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.clientes_resource.id,
      aws_api_gateway_resource.transferencias_resource.id
    ]))
  }

  rest_api_id = aws_api_gateway_rest_api.api.id
}
```

### RECURSO TIPO: AWS_API_GATEWAY_STAGE

- Que es: stage `dev`.
- Para que sirve: exponer la version publicada.
- Antes de esto: deployment.
- Campos a modificar: `stage_name`.
- Lo usan: los outputs.

```hcl
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}
```

### COMPONENTE TIPO: CREATE CLIENTE MAIN PY

- Que es: logica de la Lambda que crea clientes.
- Para que sirve: validar nombre y correo y guardar en DynamoDB.
- Antes de esto: boto3 instalado en el zip y tabla `clientes`.
- Campos a modificar: validaciones, nombre de tabla y forma del registro.
- Lo usan: `aws_lambda_function.crear_cliente`.

```python
import json
import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
tabla = dynamodb.Table("clientes")


def lambda_handler(event, context):
    try:
        print("===== NUEVO REQUEST =====")

        body = json.loads(event["body"])

        if "nombre" not in body:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "mensaje": "El nombre es obligatorio"
                })
            }

        if "correo" not in body:
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "mensaje": "El correo es obligatorio"
                })
            }

        if body["nombre"] == "":
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "mensaje": "Nombre vacio"
                })
            }

        if body["correo"] == "":
            return {
                "statusCode": 400,
                "body": json.dumps({
                    "mensaje": "Correo vacio"
                })
            }

        cliente = {
            "id": str(uuid.uuid4()),
            "nombre": body["nombre"],
            "correo": body["correo"],
            "fecha_creacion": datetime.utcnow().isoformat()
        }

        tabla.put_item(Item=cliente)

        print(f"Cliente almacenado: {cliente}")

        return {
            "statusCode": 200,
            "body": json.dumps(cliente)
        }

    except Exception as e:
        print(f"ERROR: {str(e)}")

        return {
            "statusCode": 500,
            "body": json.dumps({
                "mensaje": "Error interno"
            })
        }
```

### COMPONENTE TIPO: REALIZAR TRANSFERENCIA MAIN PY

- Que es: logica de la Lambda de transferencias.
- Para que sirve: guardar transferencias en DynamoDB.
- Antes de esto: boto3 instalado en el zip y tabla `transferencias`.
- Campos a modificar: campos del body, nombre de tabla y estructura del registro.
- Lo usan: `aws_lambda_function.realizar_transferencia`.

```python
import json
import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
tabla = dynamodb.Table("transferencias")


def lambda_handler(event, context):
    try:
        print("===== NUEVA - CHRIS MARROQUIN - TRANSFERENCIA =====")

        body = json.loads(event["body"])

        transferencia = {
            "transferencia_id": str(uuid.uuid4()),
            "cuenta_origen": body["cuenta_origen"],
            "cuenta_destino": body["cuenta_destino"],
            "monto": body["monto"],
            "fecha_transferencia": datetime.utcnow().isoformat()
        }

        tabla.put_item(Item=transferencia)

        print(f"La Transferencia fue almacenada: {transferencia}")

        return {
            "statusCode": 200,
            "body": json.dumps(transferencia)
        }

    except Exception as e:
        print(f"ERROR: {str(e)}")

        return {
            "statusCode": 500,
            "body": json.dumps({
                "mensaje": "Error en transferencia"
            })
        }
```

### COMPONENTE TIPO: REQUIREMENTS

- Que es: lista de dependencias de Python.
- Para que sirve: instalar `boto3` antes de comprimir el zip.
- Antes de esto: codigo Python listo.
- Campos a modificar: paquetes adicionales.
- Lo usan: las dos Lambdas.

```txt
boto3
```

### COMPONENTE TIPO: OUTPUTS

- Que es: URLs finales de la API.
- Para que sirve: probar los endpoints.
- Antes de esto: stage `dev`.
- Campos a modificar: ninguno.
- Lo usan: tu consola.

```hcl
output "clientes_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/clientes"
}

output "transferencias_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/transferencias"
}
```

---

## LAB API REST - LAMBDA + API GATEWAY

### COMPONENTE TIPO: PROVIDER AWS

- Que es: provider AWS del ultimo laboratorio.
- Para que sirve: crear Lambda y API Gateway.
- Antes de esto: credenciales AWS.
- Campos a modificar: version del provider y region.
- Lo usan: todos los recursos del laboratorio.

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### COMPONENTE TIPO: VARIABLE AWS_REGION

- Que es: region del ultimo laboratorio.
- Para que sirve: definir la region donde vive la API.
- Antes de esto: ninguna.
- Campos a modificar: `default`.
- Lo usan: provider y outputs.

```hcl
variable "aws_region" {
  description = "Region AWS donde se desplegaran los recursos"
  type        = string
  default     = "us-east-1"
}
```

### RECURSO TIPO: AWS_IAM_ROLE

- Que es: rol para la Lambda del API REST.
- Para que sirve: permitir ejecucion de Lambda.
- Antes de esto: provider AWS.
- Campos a modificar: `name`.
- Lo usan: Lambda y policy attachment.

```hcl
resource "aws_iam_role" "lambda_role" {
  name = "hello-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
```

### RECURSO TIPO: AWS_IAM_ROLE_POLICY_ATTACHMENT

- Que es: policy administrada para logs.
- Para que sirve: escribir en CloudWatch.
- Antes de esto: el rol debe existir.
- Campos a modificar: `policy_arn`.
- Lo usan: la Lambda.

```hcl
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

### RECURSO TIPO: AWS_LAMBDA_FUNCTION

- Que es: Lambda principal del laboratorio.
- Para que sirve: responder a `GET /hello` y `POST /saludar`.
- Antes de esto: rol IAM y `lambda.zip`.
- Campos a modificar: `function_name`, `runtime`, `handler`, `filename`.
- Lo usan: API Gateway.

```hcl
resource "aws_lambda_function" "hello_lambda" {
  function_name    = "hello-lambda"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  timeout          = 10
}
```

### RECURSO TIPO: AWS_API_GATEWAY_REST_API

- Que es: API REST.
- Para que sirve: recibir requests y enrutar a Lambda.
- Antes de esto: provider AWS.
- Campos a modificar: `name` y `description`.
- Lo usan: resources, methods, integrations y outputs.

```hcl
resource "aws_api_gateway_rest_api" "hello_api" {
  name        = "hello-api"
  description = "API REST para consumir Lambda"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_RESOURCE HELLO

- Que es: ruta `/hello`.
- Para que sirve: endpoint GET simple.
- Antes de esto: API REST.
- Campos a modificar: `path_part`.
- Lo usan: method e integration.

```hcl
resource "aws_api_gateway_resource" "hello_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
  parent_id   = aws_api_gateway_rest_api.hello_api.root_resource_id
  path_part   = "hello"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_RESOURCE SALUDAR

- Que es: ruta `/saludar`.
- Para que sirve: endpoint POST con body JSON.
- Antes de esto: API REST.
- Campos a modificar: `path_part`.
- Lo usan: method e integration.

```hcl
resource "aws_api_gateway_resource" "saludar_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
  parent_id   = aws_api_gateway_rest_api.hello_api.root_resource_id
  path_part   = "saludar"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_METHOD HELLO_GET

- Que es: metodo GET.
- Para que sirve: permitir consultas a `/hello`.
- Antes de esto: resource `/hello`.
- Campos a modificar: `http_method`, `authorization`.
- Lo usan: integration.

```hcl
resource "aws_api_gateway_method" "hello_get" {
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  resource_id   = aws_api_gateway_resource.hello_resource.id
  http_method   = "GET"
  authorization = "NONE"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_METHOD SALUDAR_POST

- Que es: metodo POST.
- Para que sirve: recibir JSON con nombre.
- Antes de esto: resource `/saludar`.
- Campos a modificar: `http_method`, `authorization`.
- Lo usan: integration.

```hcl
resource "aws_api_gateway_method" "saludar_post" {
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  resource_id   = aws_api_gateway_resource.saludar_resource.id
  http_method   = "POST"
  authorization = "NONE"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION HELLO

- Que es: integracion del GET con Lambda.
- Para que sirve: conectar `/hello` con la funcion.
- Antes de esto: method y Lambda.
- Campos a modificar: `uri`.
- Lo usan: API Gateway.

```hcl
resource "aws_api_gateway_integration" "hello_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hello_api.id
  resource_id             = aws_api_gateway_resource.hello_resource.id
  http_method             = aws_api_gateway_method.hello_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_lambda.invoke_arn
}
```

### RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION SALUDAR

- Que es: integracion del POST con Lambda.
- Para que sirve: conectar `/saludar` con la funcion.
- Antes de esto: method y Lambda.
- Campos a modificar: `uri`.
- Lo usan: API Gateway.

```hcl
resource "aws_api_gateway_integration" "saludar_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hello_api.id
  resource_id             = aws_api_gateway_resource.saludar_resource.id
  http_method             = aws_api_gateway_method.saludar_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_lambda.invoke_arn
}
```

### RECURSO TIPO: AWS_LAMBDA_PERMISSION

- Que es: permiso de invocacion.
- Para que sirve: dejar que API Gateway llame la Lambda.
- Antes de esto: Lambda y API REST.
- Campos a modificar: `source_arn`.
- Lo usan: API Gateway.

```hcl
resource "aws_lambda_permission" "allow_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.hello_api.execution_arn}/*/*"
}
```

### RECURSO TIPO: AWS_API_GATEWAY_DEPLOYMENT

- Que es: publicacion de la API.
- Para que sirve: hacer visible la configuracion nueva.
- Antes de esto: integraciones creadas.
- Campos a modificar: `triggers`, `depends_on`.
- Lo usan: el stage `dev`.

```hcl
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id

  depends_on = [
    aws_api_gateway_integration.hello_integration,
    aws_api_gateway_integration.saludar_integration
  ]

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello_resource.id,
      aws_api_gateway_method.hello_get.id,
      aws_api_gateway_integration.hello_integration.id,
      aws_api_gateway_resource.saludar_resource.id,
      aws_api_gateway_method.saludar_post.id,
      aws_api_gateway_integration.saludar_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

### RECURSO TIPO: AWS_API_GATEWAY_STAGE

- Que es: stage `dev`.
- Para que sirve: exponer la version publicada.
- Antes de esto: deployment.
- Campos a modificar: `stage_name`.
- Lo usan: outputs y pruebas.

```hcl
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  stage_name    = "dev"
}
```

### COMPONENTE TIPO: LAMBDA FUNCTION PY

- Que es: logica de respuesta del API REST.
- Para que sirve: procesar `GET /hello` y `POST /saludar`.
- Antes de esto: zip de Lambda listo.
- Campos a modificar: rutas, validaciones y mensajes.
- Lo usan: la Lambda.

```python
import json
import base64


def _response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(payload, ensure_ascii=False)
    }


def _parse_body(event):
    body = event.get("body")

    if body in (None, ""):
        raise ValueError("invalid body")

    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    return json.loads(body)


def _extract_nombre(payload):
    nombre = payload.get("nombre")

    if not isinstance(nombre, str) or not nombre.strip():
        raise ValueError("invalid nombre")

    return nombre.strip()


def lambda_handler(event, context):
    resource = event.get("resource")
    method = event.get("httpMethod")

    if resource == "/saludar" and method == "POST":
        try:
            payload = _parse_body(event)
            nombre = _extract_nombre(payload)
        except (ValueError, TypeError, json.JSONDecodeError):
            return _response(400, {
                "error": "El nombre es obligatorio"
            })

        return _response(200, {
            "mensaje": f"Hola {nombre}, bienvenido a AWS Lambda"
        })

    return _response(200, {
        "message": "Laboratorio completado exitosamente"
    })
```

### COMPONENTE TIPO: OUTPUTS

- Que es: URLs publicas.
- Para que sirve: probar los endpoints.
- Antes de esto: stage `dev`.
- Campos a modificar: ninguno.
- Lo usan: tu navegador o Postman.

```hcl
output "api_url" {
  description = "URL publica de la API"
  value       = "https://${aws_api_gateway_rest_api.hello_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev/hello"
}

output "saludar_url" {
  description = "URL publica del endpoint saludar"
  value       = "https://${aws_api_gateway_rest_api.hello_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev/saludar"
}
```

---

## RESUMEN RAPIDO DE DEPENDENCIAS

- `aws_s3_bucket` suele ser la base para `website_configuration`, `policy` y `object`.
- `aws_cloudfront_distribution` necesita un origin ya disponible.
- `aws_lambda_function` necesita rol IAM y zip armado.
- `aws_api_gateway_integration` necesita method, Lambda y permiso de invocacion.
- `aws_api_gateway_deployment` necesita las integraciones listas.
- `aws_dynamodb_table` debe existir antes de escribir desde Python.
- `provider` y `variables` van siempre primero.
