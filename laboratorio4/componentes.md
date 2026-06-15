# Componentes - Laboratorio 4

Este laboratorio combina DynamoDB, Lambda y API Gateway.

## Estructura del proyecto
- `terraform/`: infraestructura
- `lambdas/crear_cliente/`: Lambda para clientes
- `lambdas/realizar_transferencia/`: Lambda para transferencias

## Orden de estudio
1. `terraform/provider.tf`
2. `terraform/variables.tf`
3. `terraform/main.tf`
4. `lambdas/crear_cliente/main.py`
5. `lambdas/realizar_transferencia/main.py`
6. `terraform/outputs.tf`

## Requisitos previos
Antes de correr este proyecto debes tener:
- AWS CLI configurado
- permisos para crear DynamoDB, Lambda, IAM y API Gateway
- los zips de Lambda generados con sus dependencias

## COMPONENTE TIPO: PROVIDER AWS

- Descripcion: configuracion base de Terraform.
- Uso: conecta AWS con Terraform.
- Necesidades: credenciales AWS.
- Requisitos: region correcta.
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
  region = var.region
}
```

## COMPONENTE TIPO: VARIABLE REGION

- Descripcion: region de despliegue.
- Uso: define donde viven DynamoDB, Lambda y API.
- Necesidades: ninguna.
- Requisitos: region valida de AWS.
- Campos a modificar: `default`.
- Dependencias: provider.
- Codigo base:

```hcl
variable "region" {
  type    = string
  default = "us-east-1"
}
```

## COMPONENTE TIPO: RECURSO AWS_DYNAMODB_TABLE CLIENTES

- Descripcion: tabla de clientes.
- Uso: guarda registros creados por `crear_cliente`.
- Necesidades: provider AWS.
- Requisitos: clave primaria `id`.
- Campos a modificar: `name`, `hash_key`.
- Dependencias: Lambda `crear_cliente`.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_DYNAMODB_TABLE CUENTAS

- Descripcion: tabla de cuentas.
- Uso: queda como modelo de futuro.
- Necesidades: provider AWS.
- Requisitos: clave primaria `cuenta_id`.
- Campos a modificar: `name`, `hash_key`.
- Dependencias: ninguna directa en el codigo actual.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_DYNAMODB_TABLE TRANSFERENCIAS

- Descripcion: tabla de transferencias.
- Uso: guarda registros de movimiento.
- Necesidades: provider AWS.
- Requisitos: clave primaria `transferencia_id`.
- Campos a modificar: `name`, `hash_key`.
- Dependencias: Lambda `realizar_transferencia`.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_IAM_ROLE

- Descripcion: rol de ejecucion para Lambda.
- Uso: permite asumir permisos y ejecutar funciones.
- Necesidades: provider AWS.
- Requisitos: trust policy hacia `lambda.amazonaws.com`.
- Campos a modificar: `name`.
- Dependencias: policy attachment, policy inline y Lambdas.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_IAM_ROLE_POLICY_ATTACHMENT

- Descripcion: policy administrada para logs.
- Uso: permite escribir en CloudWatch.
- Necesidades: rol creado.
- Requisitos: usar la policy `AWSLambdaBasicExecutionRole`.
- Campos a modificar: `policy_arn`.
- Dependencias: rol.
- Codigo base:

```hcl
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
```

## COMPONENTE TIPO: RECURSO AWS_IAM_ROLE_POLICY

- Descripcion: policy inline para DynamoDB.
- Uso: da permisos `dynamodb:*`.
- Necesidades: rol creado.
- Requisitos: saber que aqui se usa comodin por simplicidad academica.
- Campos a modificar: `Action` y `Resource`.
- Dependencias: rol.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_LAMBDA_FUNCTION CREAR_CLIENTE

- Descripcion: Lambda que crea clientes.
- Uso: valida datos y escribe en la tabla `clientes`.
- Necesidades: zip compilado, rol IAM y tabla creada.
- Requisitos: handler `main.lambda_handler`.
- Campos a modificar: `runtime`, `handler`, `filename`.
- Dependencias: API Gateway y DynamoDB.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_LAMBDA_FUNCTION REALIZAR_TRANSFERENCIA

- Descripcion: Lambda que registra transferencias.
- Uso: escribe en la tabla `transferencias`.
- Necesidades: zip compilado, rol IAM y tabla creada.
- Requisitos: handler `main.lambda_handler`.
- Campos a modificar: `runtime`, `handler`, `filename`.
- Dependencias: API Gateway y DynamoDB.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_REST_API

- Descripcion: API principal.
- Uso: expone los endpoints publicos.
- Necesidades: provider AWS.
- Requisitos: nombre claro para el API.
- Campos a modificar: `name`.
- Dependencias: resources, methods, integrations y stage.
- Codigo base:

```hcl
resource "aws_api_gateway_rest_api" "api" {
  name = "laboratorio-api"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_RESOURCE CLIENTES

- Descripcion: ruta `/clientes`.
- Uso: endpoint para crear clientes.
- Necesidades: API REST.
- Requisitos: `path_part = "clientes"`.
- Campos a modificar: `path_part`.
- Dependencias: method e integration.
- Codigo base:

```hcl
resource "aws_api_gateway_resource" "clientes_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "clientes"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_METHOD CLIENTES_POST

- Descripcion: metodo POST de clientes.
- Uso: recibe el request HTTP.
- Necesidades: resource `/clientes`.
- Requisitos: `authorization = "NONE"` si es publico.
- Campos a modificar: `http_method`, `authorization`.
- Dependencias: integration.
- Codigo base:

```hcl
resource "aws_api_gateway_method" "clientes_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.clientes_resource.id
  http_method   = "POST"
  authorization = "NONE"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_INTEGRATION CLIENTES

- Descripcion: integracion de clientes.
- Uso: conecta API Gateway con la Lambda `crear_cliente`.
- Necesidades: method y Lambda.
- Requisitos: tipo `AWS_PROXY`.
- Campos a modificar: `uri`.
- Dependencias: permiso Lambda.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_LAMBDA_PERMISSION CLIENTES

- Descripcion: permiso para invocar la Lambda de clientes.
- Uso: deja que API Gateway la ejecute.
- Necesidades: Lambda y API REST.
- Requisitos: `principal = "apigateway.amazonaws.com"`.
- Campos a modificar: `statement_id`, `source_arn`.
- Dependencias: integration.
- Codigo base:

```hcl
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.crear_cliente.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_RESOURCE TRANSFERENCIAS

- Descripcion: ruta `/transferencias`.
- Uso: endpoint para registrar movimientos.
- Necesidades: API REST.
- Requisitos: `path_part = "transferencias"`.
- Campos a modificar: `path_part`.
- Dependencias: method e integration.
- Codigo base:

```hcl
resource "aws_api_gateway_resource" "transferencias_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "transferencias"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_METHOD TRANSFERENCIAS_POST

- Descripcion: metodo POST de transferencias.
- Uso: recibe el request HTTP.
- Necesidades: resource `/transferencias`.
- Requisitos: `authorization = "NONE"` si es publico.
- Campos a modificar: `http_method`, `authorization`.
- Dependencias: integration.
- Codigo base:

```hcl
resource "aws_api_gateway_method" "transferencias_post" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.transferencias_resource.id
  http_method   = "POST"
  authorization = "NONE"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_INTEGRATION TRANSFERENCIAS

- Descripcion: integracion de transferencias.
- Uso: conecta API Gateway con la Lambda `realizar_transferencia`.
- Necesidades: method y Lambda.
- Requisitos: tipo `AWS_PROXY`.
- Campos a modificar: `uri`.
- Dependencias: permiso Lambda.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_LAMBDA_PERMISSION TRANSFERENCIAS

- Descripcion: permiso para invocar la Lambda de transferencias.
- Uso: deja que API Gateway la ejecute.
- Necesidades: Lambda y API REST.
- Requisitos: `principal = "apigateway.amazonaws.com"`.
- Campos a modificar: `statement_id`, `source_arn`.
- Dependencias: integration.
- Codigo base:

```hcl
resource "aws_lambda_permission" "transferencias_permission" {
  statement_id  = "AllowTransferenciasInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.realizar_transferencia.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
```

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_DEPLOYMENT

- Descripcion: publica la API.
- Uso: hace visibles los recursos y metodos.
- Necesidades: integraciones creadas.
- Requisitos: `triggers` para redeploy cuando cambie algo.
- Campos a modificar: `depends_on`, `triggers`.
- Dependencias: stage.
- Codigo base:

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

## COMPONENTE TIPO: RECURSO AWS_API_GATEWAY_STAGE

- Descripcion: stage `dev`.
- Uso: expone la version publicada.
- Necesidades: deployment creado.
- Requisitos: nombre del stage claro.
- Campos a modificar: `stage_name`.
- Dependencias: outputs.
- Codigo base:

```hcl
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"
}
```

## COMPONENTE TIPO: MAIN.PY CREAR CLIENTE

- Descripcion: logica de la Lambda de clientes.
- Uso: valida nombre y correo, crea un id y guarda el registro.
- Necesidades: `boto3` y tabla `clientes`.
- Requisitos: body JSON con `nombre` y `correo`.
- Campos a modificar: validaciones, nombre de tabla y atributos del Item.
- Dependencias: Lambda y API Gateway.
- Codigo base:

```python
import json
import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
tabla = dynamodb.Table("clientes")


def lambda_handler(event, context):
    try:
        body = json.loads(event["body"])

        if "nombre" not in body:
            return {"statusCode": 400, "body": json.dumps({"mensaje": "El nombre es obligatorio"})}

        if "correo" not in body:
            return {"statusCode": 400, "body": json.dumps({"mensaje": "El correo es obligatorio"})}

        if body["nombre"] == "":
            return {"statusCode": 400, "body": json.dumps({"mensaje": "Nombre vacio"})}

        if body["correo"] == "":
            return {"statusCode": 400, "body": json.dumps({"mensaje": "Correo vacio"})}

        cliente = {
            "id": str(uuid.uuid4()),
            "nombre": body["nombre"],
            "correo": body["correo"],
            "fecha_creacion": datetime.utcnow().isoformat()
        }

        tabla.put_item(Item=cliente)

        return {"statusCode": 200, "body": json.dumps(cliente)}

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"mensaje": "Error interno"})}
```

## COMPONENTE TIPO: MAIN.PY REALIZAR TRANSFERENCIA

- Descripcion: logica de la Lambda de transferencias.
- Uso: guarda la transferencia en DynamoDB.
- Necesidades: `boto3` y tabla `transferencias`.
- Requisitos: body JSON con `cuenta_origen`, `cuenta_destino` y `monto`.
- Campos a modificar: campos del registro y validaciones.
- Dependencias: Lambda y API Gateway.
- Codigo base:

```python
import json
import boto3
import uuid
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
tabla = dynamodb.Table("transferencias")


def lambda_handler(event, context):
    try:
        body = json.loads(event["body"])

        transferencia = {
            "transferencia_id": str(uuid.uuid4()),
            "cuenta_origen": body["cuenta_origen"],
            "cuenta_destino": body["cuenta_destino"],
            "monto": body["monto"],
            "fecha_transferencia": datetime.utcnow().isoformat()
        }

        tabla.put_item(Item=transferencia)

        return {"statusCode": 200, "body": json.dumps(transferencia)}

    except Exception as e:
        return {"statusCode": 500, "body": json.dumps({"mensaje": "Error en transferencia"})}
```

## COMPONENTE TIPO: REQUIREMENTS

- Descripcion: dependencias de Python.
- Uso: instalar paquetes antes de crear el zip.
- Necesidades: saber que Lambda usa `boto3`.
- Requisitos: correr instalacion dentro de la carpeta de cada Lambda.
- Campos a modificar: paquetes extras.
- Dependencias: los zips de Lambda.
- Codigo base:

```txt
boto3
```

## COMPONENTE TIPO: OUTPUTS

- Descripcion: URLs publicas de la API.
- Uso: probar los endpoints.
- Necesidades: stage `dev`.
- Requisitos: ningun extra.
- Campos a modificar: ninguno.
- Dependencias: stage.
- Codigo base:

```hcl
output "clientes_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/clientes"
}

output "transferencias_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/transferencias"
}
```

## Resumen rapido
- DynamoDB guarda los datos.
- IAM da permisos a Lambda.
- API Gateway publica los endpoints.
- Las Lambdas hacen la logica de negocio.
- Los zips y requirements son parte del flujo real de despliegue.
