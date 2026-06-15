# Componentes - Lab API REST

Este laboratorio crea una API REST con Lambda en Python.

## Orden de estudio
1. `provider.tf`
2. `variables.tf`
3. `main.tf`
4. `lambda_function.py`
5. `outputs.tf`

## Requisitos previos
Antes de correrlo debes tener:
- AWS CLI configurado
- permisos para crear IAM, Lambda y API Gateway
- el archivo `lambda.zip` listo

## COMPONENTE TIPO: PROVIDER AWS

- Descripcion: configuracion base de Terraform.
- Uso: conecta Terraform con AWS y define la region.
- Necesidades: credenciales AWS.
- Requisitos: version compatible de Terraform y provider.
- Campos a modificar: `required_version`, version del provider y `region`.
- Dependencias: todo el laboratorio.
- Codigo base:

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

## COMPONENTE TIPO: VARIABLE AWS_REGION

- Descripcion: region del despliegue.
- Uso: cambia la region sin tocar el provider.
- Necesidades: ninguna.
- Requisitos: region valida.
- Campos a modificar: `default`.
- Dependencias: provider y outputs.
- Codigo base:

```hcl
variable "aws_region" {
  description = "Region AWS donde se desplegaran los recursos"
  type        = string
  default     = "us-east-1"
}
```

## COMPONENTE TIPO: RECURSO AWS_IAM_ROLE

- Descripcion: rol de ejecucion para Lambda.
- Uso: permite que Lambda se ejecute.
- Necesidades: provider AWS.
- Requisitos: trust policy para `lambda.amazonaws.com`.
- Campos a modificar: `name`.
- Dependencias: policy attachment, Lambda.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_IAM_ROLE_POLICY_ATTACHMENT

- Descripcion: policy administrada para logs.
- Uso: permite escribir en CloudWatch.
- Necesidades: rol creado.
- Requisitos: `AWSLambdaBasicExecutionRole`.
- Campos a modificar: `policy_arn`.
- Dependencias: rol.
- Codigo base:

```hcl
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

## COMPONENTE TIPO: RECURSO AWS_LAMBDA_FUNCTION

- Descripcion: Lambda principal.
- Uso: responde a `GET /hello` y `POST /saludar`.
- Necesidades: rol IAM y `lambda.zip`.
- Requisitos: handler `lambda_function.lambda_handler`.
- Campos a modificar: `function_name`, `runtime`, `handler`, `filename`.
- Dependencias: API Gateway.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_REST_API

- Descripcion: API REST.
- Uso: recibe requests y los manda a Lambda.
- Necesidades: provider AWS.
- Requisitos: nombre claro del API.
- Campos a modificar: `name` y `description`.
- Dependencias: resources, methods, integrations, deployment y stage.
- Codigo base:

```hcl
resource "aws_api_gateway_rest_api" "hello_api" {
  name        = "hello-api"
  description = "API REST para consumir Lambda"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_RESOURCE HELLO

- Descripcion: ruta `/hello`.
- Uso: endpoint GET.
- Necesidades: API REST creada.
- Requisitos: `path_part = "hello"`.
- Campos a modificar: `path_part`.
- Dependencias: method e integration.
- Codigo base:

```hcl
resource "aws_api_gateway_resource" "hello_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
  parent_id   = aws_api_gateway_rest_api.hello_api.root_resource_id
  path_part   = "hello"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_RESOURCE SALUDAR

- Descripcion: ruta `/saludar`.
- Uso: endpoint POST.
- Necesidades: API REST creada.
- Requisitos: `path_part = "saludar"`.
- Campos a modificar: `path_part`.
- Dependencias: method e integration.
- Codigo base:

```hcl
resource "aws_api_gateway_resource" "saludar_resource" {
  rest_api_id = aws_api_gateway_rest_api.hello_api.id
  parent_id   = aws_api_gateway_rest_api.hello_api.root_resource_id
  path_part   = "saludar"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_METHOD HELLO_GET

- Descripcion: metodo GET.
- Uso: habilita la ruta `/hello`.
- Necesidades: resource `/hello`.
- Requisitos: `authorization = "NONE"` si es publico.
- Campos a modificar: `http_method`, `authorization`.
- Dependencias: integration.
- Codigo base:

```hcl
resource "aws_api_gateway_method" "hello_get" {
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  resource_id   = aws_api_gateway_resource.hello_resource.id
  http_method   = "GET"
  authorization = "NONE"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_METHOD SALUDAR_POST

- Descripcion: metodo POST.
- Uso: habilita la ruta `/saludar`.
- Necesidades: resource `/saludar`.
- Requisitos: `authorization = "NONE"` si es publico.
- Campos a modificar: `http_method`, `authorization`.
- Dependencias: integration.
- Codigo base:

```hcl
resource "aws_api_gateway_method" "saludar_post" {
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  resource_id   = aws_api_gateway_resource.saludar_resource.id
  http_method   = "POST"
  authorization = "NONE"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_INTEGRATION HELLO

- Descripcion: integracion GET -> Lambda.
- Uso: envía `GET /hello` a la Lambda.
- Necesidades: method y Lambda.
- Requisitos: tipo `AWS_PROXY`.
- Campos a modificar: `uri`.
- Dependencias: permiso Lambda.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_INTEGRATION SALUDAR

- Descripcion: integracion POST -> Lambda.
- Uso: envía `POST /saludar` a la Lambda.
- Necesidades: method y Lambda.
- Requisitos: tipo `AWS_PROXY`.
- Campos a modificar: `uri`.
- Dependencias: permiso Lambda.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_LAMBDA_PERMISSION

- Descripcion: permiso de invocacion.
- Uso: deja que API Gateway llame la Lambda.
- Necesidades: Lambda y API REST.
- Requisitos: `principal = "apigateway.amazonaws.com"`.
- Campos a modificar: `statement_id`, `source_arn`.
- Dependencias: deployment y stage.
- Codigo base:

```hcl
resource "aws_lambda_permission" "allow_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.hello_api.execution_arn}/*/*"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_DEPLOYMENT

- Descripcion: publica la API.
- Uso: hace visibles los cambios.
- Necesidades: integraciones creadas.
- Requisitos: `create_before_destroy = true` si quieres redeploy limpio.
- Campos a modificar: `triggers` y `depends_on`.
- Dependencias: stage.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_STAGE

- Descripcion: stage `dev`.
- Uso: expone la version publicada.
- Necesidades: deployment creado.
- Requisitos: stage name consistente con los outputs.
- Campos a modificar: `stage_name`.
- Dependencias: outputs.
- Codigo base:

```hcl
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.hello_api.id
  stage_name    = "dev"
}
```

## COMPONENTE TIPO: LAMBDA_FUNCTION.PY

- Descripcion: logica de negocio.
- Uso: responde según ruta y metodo HTTP.
- Necesidades: `lambda.zip`.
- Requisitos: `resource` y `httpMethod` correctos en el evento.
- Campos a modificar: validaciones, mensajes y rutas.
- Dependencias: Lambda empaquetada.
- Codigo base:

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

## COMPONENTE TIPO: OUTPUTS

- Descripcion: URLs publicas.
- Uso: probar los endpoints.
- Necesidades: stage `dev`.
- Requisitos: ninguno extra.
- Campos a modificar: `value`.
- Dependencias: stage.
- Codigo base:

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

## Resumen rapido
- IAM da permisos a Lambda.
- API Gateway publica la API.
- Lambda responde a los endpoints.
- `AWS_PROXY` simplifica la integracion.
- `outputs` te dan la URL final.
