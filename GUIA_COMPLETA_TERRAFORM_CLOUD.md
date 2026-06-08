# Guia completa de Terraform para los 4 laboratorios

Esta guia centraliza el contenido de:
- `lab-api-rest`
- `laboratorio2-s3`
- `laboratorio3-cloudfront`
- `laboratorio4`



## Regla mental para Terraform
En casi todos los proyectos el orden logico es:
1. Configuracion base: `terraform`, `provider`, `variables`.
2. Identidad y permisos: `iam_role`, `policy_attachment`, `policy`.
3. Recursos principales: `s3`, `lambda`, `dynamodb`, `api gateway`.
4. Conexiones: `integration`, `permission`, `deployment`, `stage`.
5. Salidas: `outputs`.

---

# 1. Lab API REST

## Que hace
Este laboratorio crea una API REST con API Gateway y una Lambda en Python.

## Orden practico de creacion
1. `provider.tf`
2. `variables.tf`
3. `main.tf`
4. `lambda_function.py`
5. `outputs.tf`

## Idea principal de la arquitectura
- API Gateway recibe el request.
- API Gateway llama a Lambda.
- Lambda valida el request y responde JSON.
- Terraform deja todo reproducible.

## Fragmentos completos

### `lab-api-rest/provider.tf`
```hcl
terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Define la version minima de Terraform y el provider AWS que se usara.
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # Esta region controla donde se crean los recursos del laboratorio.
  region = var.aws_region
}
```

### `lab-api-rest/variables.tf`
```hcl
variable "aws_region" {
  # VARIABLE TIPO: AWS_REGION
  # Region donde se desplegara toda la infraestructura.
  description = "Region AWS donde se desplegaran los recursos"
  type        = string
  default     = "us-east-1"
}
```

### `lab-api-rest/main.tf`
```hcl
// RECURSO TIPO: AWS_IAM_ROLE
// Rol que permite a Lambda asumir permisos para ejecutarse.
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

// RECURSO TIPO: AWS_IAM_ROLE_POLICY_ATTACHMENT
// Adjunta la politica basica para que Lambda escriba logs en CloudWatch.
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// RECURSO TIPO: AWS_LAMBDA_FUNCTION
// Funcion principal del laboratorio. Ejecuta lambda_function.py empaquetado en lambda.zip.
resource "aws_lambda_function" "hello_lambda" {
  function_name    = "hello-lambda"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "lambda.zip"
  source_code_hash = filebase64sha256("lambda.zip")
  timeout          = 10
}

// RECURSO TIPO: AWS_API_GATEWAY_REST_API
// Crea la API REST que actuara como puerta de entrada.
resource "aws_api_gateway_rest_api" "hello_api" {
  name        = "hello-api"
  description = "API REST para consumir Lambda"
}

// RECURSO TIPO: AWS_API_GATEWAY_RESOURCE
// Ruta /hello dentro de la API.
resource "aws_api_gateway_resource" "hello_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
  parent_id   = aws_api_gateway_rest_api.hello_api.root_resource_id
  path_part   = "hello"
}

// RECURSO TIPO: AWS_API_GATEWAY_RESOURCE
// Ruta /saludar dentro de la API.
resource "aws_api_gateway_resource" "saludar_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
  parent_id   = aws_api_gateway_rest_api.hello_api.root_resource_id
  path_part   = "saludar"
}

// RECURSO TIPO: AWS_API_GATEWAY_METHOD
// Metodo GET para /hello.
resource "aws_api_gateway_method" "hello_get" {
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  resource_id   = aws_api_gateway_resource.hello_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

// RECURSO TIPO: AWS_API_GATEWAY_METHOD
// Metodo POST para /saludar. Recibe un JSON con el nombre.
resource "aws_api_gateway_method" "saludar_post" {
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  resource_id   = aws_api_gateway_resource.saludar_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

// RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION
// Une GET /hello con la Lambda usando proxy integration.
resource "aws_api_gateway_integration" "hello_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hello_api.id
  resource_id             = aws_api_gateway_resource.hello_resource.id
  http_method             = aws_api_gateway_method.hello_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_lambda.invoke_arn
}

// RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION
// Une POST /saludar con la misma Lambda.
resource "aws_api_gateway_integration" "saludar_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hello_api.id
  resource_id             = aws_api_gateway_resource.saludar_resource.id
  http_method             = aws_api_gateway_method.saludar_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello_lambda.invoke_arn
}

// RECURSO TIPO: AWS_LAMBDA_PERMISSION
// Permite que API Gateway invoque la funcion Lambda.
resource "aws_lambda_permission" "allow_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.hello_api.execution_arn}/*/*"
}

// RECURSO TIPO: AWS_API_GATEWAY_DEPLOYMENT
// Publica la API con los recursos y metodos ya creados.
// El trigger fuerza redeploy cuando cambia la estructura.
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

  // Crea el nuevo deployment antes de destruir el anterior.
  lifecycle {
    create_before_destroy = true
  }
}

// RECURSO TIPO: AWS_API_GATEWAY_STAGE
// El stage "dev" es la version publicada de la API.
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  stage_name    = "dev"

  // Asegura que el stage se cree despues del deployment.
  depends_on = [
    aws_api_gateway_deployment.deployment
  ]
}
```

### `lab-api-rest/lambda_function.py`
```python
import json
import base64


# FUNCION AUXILIAR: _response
# Estandariza la respuesta de la Lambda con el formato esperado por API Gateway.
def _response(status_code, payload):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(payload, ensure_ascii=False)
    }


# FUNCION AUXILIAR: _parse_body
# Lee el body del request y lo convierte desde JSON.
# Si el body viene en base64, primero lo decodifica.
def _parse_body(event):
    body = event.get("body")

    if body in (None, ""):
        raise ValueError("invalid body")

    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    return json.loads(body)


# FUNCION AUXILIAR: _extract_nombre
# Valida que el campo nombre exista, sea texto y no venga vacio.
def _extract_nombre(payload):
    nombre = payload.get("nombre")

    if not isinstance(nombre, str) or not nombre.strip():
        raise ValueError("invalid nombre")

    return nombre.strip()


# FUNCION PRINCIPAL: lambda_handler
# Esta es la funcion que AWS Lambda ejecuta en cada request.
# Segun el recurso y el metodo HTTP, decide que respuesta devolver.
def lambda_handler(event, context):
    resource = event.get("resource")
    method = event.get("httpMethod")

    # RUTA: POST /saludar
    # Esta ruta exige un JSON con {"nombre": "..."}.
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

    # RESPUESTA POR DEFECTO
    # Si no entra en la ruta /saludar, devuelve el mensaje general del laboratorio.
    return _response(200, {
        "message": "Laboratorio completado exitosamente"
    })
```

### `lab-api-rest/outputs.tf`
```hcl
output "api_url" {
  # SALIDA PRINCIPAL
  # URL publica del endpoint GET /hello.
  description = "URL publica de la API"
  value       = "https://${aws_api_gateway_rest_api.hello_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev/hello"
}

output "saludar_url" {
  # SALIDA SECUNDARIA
  # URL publica del endpoint POST /saludar.
  description = "URL publica del endpoint saludar"
  value       = "https://${aws_api_gateway_rest_api.hello_api.id}.execute-api.${var.aws_region}.amazonaws.com/dev/saludar"
}
```

## Resumen de examen
- `aws_lambda_permission` es la llave que deja que API Gateway invoque Lambda.
- `aws_api_gateway_deployment` es necesario para publicar cambios.
- `AWS_PROXY` simplifica la integracion.
- `lambda_function.py` debe devolver `statusCode`, `headers` y `body`.

---

# 2. Laboratorio 2: S3 estatico

## Que hace
Publica un sitio web estatico desde un bucket S3.

## Orden practico de creacion
1. `provider.tf`
2. `main.tf`
3. `index.html`
4. `outputs.tf`

## Idea principal de la arquitectura
- S3 guarda el sitio.
- Website configuration habilita hosting.
- Bucket policy permite lectura publica.
- El objeto `index.html` es la pagina principal.

## Fragmentos completos

### `laboratorio2-s3/provider.tf`
```hcl
terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Este laboratorio usa AWS como provider principal.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # Se fija la region donde vivira el bucket y sus objetos.
  region = "us-east-1"
}
```

### `laboratorio2-s3/main.tf`
```hcl
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
```

### `laboratorio2-s3/index.html`
```html
<!DOCTYPE html>
<html>
<head>
   <!-- RECURSO TIPO: HTML_BASE -->
   <!-- Este archivo es el contenido estatico que se publica en S3. -->
   <title>Laboratorio 2</title>
</head>
<body>
   <h1>Sitio Web Desplegado con Terraform</h1>
   <p>Laboratorio completado correctamente.</p>
</body>
</html>
```

### `laboratorio2-s3/outputs.tf`
```hcl
output "website_url" {
  # SALIDA PRINCIPAL
  # Endpoint del hosting estatico de S3.
  value = aws_s3_bucket_website_configuration.sitio_web.website_endpoint
}
```

## Resumen de examen
- El bucket debe ser unico.
- Para hosting web se necesita `aws_s3_bucket_website_configuration`.
- La policy publica es indispensable.
- `aws_s3_object` sube el contenido web.

---

# 3. Laboratorio 3: CloudFront + S3

## Que hace
Toma un sitio estatico y lo sirve a traves de CloudFront usando S3 como origen.

## Orden practico de creacion
1. `provider.tf`
2. `variables.tf`
3. `terraform.tfvars`
4. `main.tf`
5. `index.html`
6. `style.css`
7. `outputs.tf`

## Idea principal de la arquitectura
- S3 guarda los archivos.
- CloudFront lee desde el endpoint website de S3.
- CloudFront cachea y entrega el contenido mas rapido.
- El sitio fuerza HTTPS.

## Fragmentos completos

### `laboratorio3-cloudfront/provider.tf`
```hcl
terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Se usa AWS como provider para desplegar S3 + CloudFront.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # CloudFront es global, pero el origen S3 de este laboratorio vive en us-east-1.
  region = "us-east-1"
}
```

### `laboratorio3-cloudfront/variables.tf`
```hcl
variable "bucket_name" {
  # VARIABLE TIPO: BUCKET_NAME
  # Nombre del bucket S3 ya existente que servira como origen.
  type = string
}
```

### `laboratorio3-cloudfront/terraform.tfvars`
```hcl
# VALOR CONCRETO DE LA VARIABLE bucket_name
# Este es el bucket origen que CloudFront usara para leer los archivos.
bucket_name = "laboratorio2-marroquinchristopher-2026"
```

### `laboratorio3-cloudfront/main.tf`
```hcl
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
```

### `laboratorio3-cloudfront/index.html`
```html
<!DOCTYPE html>
<html>
<head>
   <!-- RECURSO TIPO: HTML_BASE -->
   <!-- Este archivo es la pagina principal servida por CloudFront. -->
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

### `laboratorio3-cloudfront/style.css`
```css
/* RECURSO TIPO: CSS_BASE
   Este archivo define la apariencia visual del sitio. */
body {
   font-family: Arial;
   background-color: #f5f5f5;
   text-align: center;
}

h1 {
   color: #ff9900;
}
```

### `laboratorio3-cloudfront/outputs.tf`
```hcl
output "cloudfront_url" {
  # SALIDA PRINCIPAL
  # Dominio publico de la distribucion CloudFront.
  value = aws_cloudfront_distribution.sitio_web.domain_name
}
```

## Resumen de examen
- CloudFront usa el origin de S3.
- `default_root_object` define la pagina de entrada.
- `redirect-to-https` mejora seguridad.
- `forwarded_values` controla que se cachea.

---

# 4. Laboratorio 4: API, Lambda y DynamoDB

## Que hace
Este laboratorio expone dos endpoints REST con API Gateway:
- `POST /clientes`
- `POST /transferencias`

Cada uno escribe en DynamoDB usando una Lambda distinta.

## Orden practico de creacion
1. `terraform/provider.tf`
2. `terraform/variables.tf`
3. `terraform/main.tf`
4. `lambdas/crear_cliente/main.py`
5. `lambdas/realizar_transferencia/main.py`
6. `terraform/outputs.tf`

## Idea principal de la arquitectura
- API Gateway recibe el request.
- Lambda valida y arma el registro.
- DynamoDB guarda el dato.
- Terraform publica todo y deja las URLs listas.

## Fragmentos completos

### `laboratorio4/terraform/provider.tf`
```hcl
terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Define el provider AWS que usara este laboratorio.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # Region donde se creara la base de datos, Lambda y API Gateway.
  region = var.region
}
```

### `laboratorio4/terraform/variables.tf`
```hcl
variable "region" {
  # VARIABLE TIPO: REGION
  # Region AWS donde se despliega toda la solucion.
  type    = string
  default = "us-east-1"
}
```

### `laboratorio4/terraform/main.tf`
```hcl
// RECURSO TIPO: AWS_DYNAMODB_TABLE
// Tabla que guarda clientes del sistema.
resource "aws_dynamodb_table" "clientes" {
  name         = "clientes"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

// RECURSO TIPO: AWS_DYNAMODB_TABLE
// Tabla para cuentas. En este laboratorio se crea como parte del modelo de datos.
resource "aws_dynamodb_table" "cuentas" {
  name         = "cuentas"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "cuenta_id"

  attribute {
    name = "cuenta_id"
    type = "S"
  }
}

// RECURSO TIPO: AWS_DYNAMODB_TABLE
// Tabla que guarda el historial de transferencias.
resource "aws_dynamodb_table" "transferencias" {
  name         = "transferencias"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "transferencia_id"

  attribute {
    name = "transferencia_id"
    type = "S"
  }
}

// RECURSO TIPO: AWS_IAM_ROLE
// Rol que Lambda asumira para escribir logs y acceder a DynamoDB.
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

// RECURSO TIPO: AWS_IAM_ROLE_POLICY_ATTACHMENT
// Politica administrada para que Lambda escriba logs en CloudWatch.
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

// RECURSO TIPO: AWS_IAM_ROLE_POLICY
// Politica inline que da permisos completos sobre DynamoDB.
// En un examen conviene recordar que aqui se usa comodin por simplicidad.
resource "aws_iam_role_policy" "dynamodb_policy" {
  name = "dynamodb_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:*"
      ]
      Resource = "*"
    }]
  })
}

// RECURSO TIPO: AWS_LAMBDA_FUNCTION
// Lambda que crea clientes y guarda registros en DynamoDB.
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

// RECURSO TIPO: AWS_LAMBDA_FUNCTION
// Lambda que registra transferencias en DynamoDB.
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

// RECURSO TIPO: AWS_API_GATEWAY_REST_API
// API unica que expone los endpoints del laboratorio.
resource "aws_api_gateway_rest_api" "api" {
  name = "laboratorio-api"
}

// =========================
// API GATEWAY /clientes
// =========================

// RECURSO TIPO: AWS_API_GATEWAY_RESOURCE
// Ruta /clientes dentro de la API.
resource "aws_api_gateway_resource" "clientes_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "clientes"
}

// RECURSO TIPO: AWS_API_GATEWAY_METHOD
// Metodo POST para crear clientes.
resource "aws_api_gateway_method" "clientes_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.clientes_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

// RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION
// Conecta POST /clientes con la Lambda crear_cliente.
resource "aws_api_gateway_integration" "clientes_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.clientes_resource.id
  http_method             = aws_api_gateway_method.clientes_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.crear_cliente.invoke_arn
}

// RECURSO TIPO: AWS_LAMBDA_PERMISSION
// Permite que API Gateway invoque la Lambda de clientes.
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crear_cliente.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

// =========================
// API GATEWAY /transferencias
// =========================

// RECURSO TIPO: AWS_API_GATEWAY_RESOURCE
// Ruta /transferencias dentro de la API.
resource "aws_api_gateway_resource" "transferencias_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "transferencias"
}

// RECURSO TIPO: AWS_API_GATEWAY_METHOD
// Metodo POST para registrar transferencias.
resource "aws_api_gateway_method" "transferencias_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.transferencias_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

// RECURSO TIPO: AWS_API_GATEWAY_INTEGRATION
// Conecta POST /transferencias con la Lambda realizar_transferencia.
resource "aws_api_gateway_integration" "transferencias_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.transferencias_resource.id
  http_method             = aws_api_gateway_method.transferencias_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.realizar_transferencia.invoke_arn
}

// RECURSO TIPO: AWS_LAMBDA_PERMISSION
// Permite que API Gateway invoque la Lambda de transferencias.
resource "aws_lambda_permission" "transferencias_permission" {
  statement_id  = "AllowTransferenciasInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.realizar_transferencia.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

// RECURSO TIPO: AWS_API_GATEWAY_DEPLOYMENT
// Publica la API con ambos endpoints activos.
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

// RECURSO TIPO: AWS_API_GATEWAY_STAGE
// Stage dev que expone la version publicada de la API.
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}
```

### `laboratorio4/terraform/outputs.tf`
```hcl
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
```

### `laboratorio4/lambdas/crear_cliente/main.py`
```python
import json
import boto3
import uuid
from datetime import datetime

# RECURSO TIPO: CONEXION A DYNAMODB
# Se crea una referencia al servicio DynamoDB y se selecciona la tabla clientes.
dynamodb = boto3.resource("dynamodb")
tabla = dynamodb.Table("clientes")


# FUNCION PRINCIPAL: lambda_handler
# Recibe el evento de API Gateway, valida el body y guarda un nuevo cliente.
def lambda_handler(event, context):
    try:
        print("===== NUEVO REQUEST =====")

        body = json.loads(event["body"])

        # VALIDACION DE ENTRADA
        # El laboratorio exige nombre y correo.
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

        # ARMADO DEL REGISTRO
        # Se genera un id unico y se agrega fecha de creacion.
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

### `laboratorio4/lambdas/realizar_transferencia/main.py`
```python
import json
import boto3
import uuid
from datetime import datetime

# RECURSO TIPO: CONEXION A DYNAMODB
# Esta Lambda escribe en la tabla transferencias.
dynamodb = boto3.resource("dynamodb")
tabla = dynamodb.Table("transferencias")


# FUNCION PRINCIPAL: lambda_handler
# Registra una transferencia sencilla usando los datos recibidos en el body.
def lambda_handler(event, context):
    try:
        print("===== NUEVA - CHRIS MARROQUIN - TRANSFERENCIA =====")

        body = json.loads(event["body"])

        # ARMADO DEL REGISTRO
        # Se guarda la informacion basica de origen, destino, monto y fecha.
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

### `laboratorio4/lambdas/crear_cliente/requirements.txt`
```txt
# DEPENDENCIA PRINCIPAL PARA LA LAMBDA
boto3
```

### `laboratorio4/lambdas/realizar_transferencia/requirements.txt`
```txt
# DEPENDENCIA PRINCIPAL PARA LA LAMBDA
boto3
```

## Resumen de examen
- DynamoDB necesita clave primaria con `hash_key`.
- `PAY_PER_REQUEST` evita definir capacidad manual.
- `boto3.resource("dynamodb")` es la puerta de Python a DynamoDB.
- La API usa `AWS_PROXY`, asi que Lambda recibe el evento completo.
- `aws_lambda_permission` es obligatoria para que API Gateway pueda invocar la Lambda.

---

# Conclusiones generales

## Conceptos que se repiten en los 4 laboratorios
- `provider`: dice a que AWS apuntar.
- `resource`: crea un recurso real.
- `output`: muestra datos utiles al terminar.
- `depends_on`: ordena dependencias cuando Terraform no puede inferirlas.
- `jsonencode()`: convierte estructuras de Terraform a JSON valido.
- `source_code_hash`: obliga a redeploy cuando cambia el zip.

## Flujo mental recomendado
1. Identifica el servicio principal.
2. Busca quien lo ejecuta o entrega.
3. Revisa los permisos.
4. Revisa el punto de entrada.
5. Verifica la salida final.
