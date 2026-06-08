# Laboratorio 4: API, Lambda y DynamoDB

## Objetivo
Este proyecto crea una API REST con dos Lambdas:
- `POST /clientes`
- `POST /transferencias`

Cada Lambda escribe informacion en DynamoDB.

## Estructura del proyecto
- `terraform/`: infraestructura principal con Terraform.
- `lambdas/crear_cliente/`: codigo de la Lambda que crea clientes.
- `lambdas/realizar_transferencia/`: codigo de la Lambda que registra transferencias.

## Orden recomendado para entenderlo
1. `terraform/provider.tf`
2. `terraform/variables.tf`
3. `terraform/main.tf`
4. `lambdas/crear_cliente/main.py`
5. `lambdas/realizar_transferencia/main.py`
6. `terraform/outputs.tf`

## Que hace cada parte
### `terraform/provider.tf`
Define el provider AWS y la region.

### `terraform/variables.tf`
Contiene la variable `region`.

### `terraform/main.tf`
Aqui esta toda la infraestructura:
- `aws_dynamodb_table`: crea `clientes`, `cuentas` y `transferencias`.
- `aws_iam_role`: rol base para Lambda.
- `aws_iam_role_policy_attachment`: logs en CloudWatch.
- `aws_iam_role_policy`: permisos sobre DynamoDB.
- `aws_lambda_function`: crea las dos funciones.
- `aws_api_gateway_rest_api`: crea la API.
- `aws_api_gateway_resource`: define `/clientes` y `/transferencias`.
- `aws_api_gateway_method`: define los POST.
- `aws_api_gateway_integration`: conecta cada ruta con su Lambda.
- `aws_lambda_permission`: permite las invocaciones.
- `aws_api_gateway_deployment`: publica la API.
- `aws_api_gateway_stage`: expone `dev`.

### `lambdas/crear_cliente/main.py`
Valida `nombre` y `correo`, crea un id unico y guarda el cliente en DynamoDB.

### `lambdas/realizar_transferencia/main.py`
Recibe datos de cuenta origen, destino y monto, luego guarda la transferencia.

### `terraform/outputs.tf`
Muestra las URLs publicas de ambos endpoints.

## Orden de creacion en Terraform
1. Crear tablas DynamoDB.
2. Crear rol IAM.
3. Adjuntar politica de logs.
4. Agregar politica de DynamoDB.
5. Crear y empaquetar las Lambdas.
6. Crear API Gateway.
7. Crear recursos, metodos e integraciones.
8. Dar permisos a API Gateway.
9. Crear el deployment.
10. Crear el stage `dev`.
11. Revisar los outputs.

## Que debe tener para funcionar
- Las tablas DynamoDB deben existir antes de que las Lambdas escriban.
- Las Lambdas deben estar empaquetadas en `lambda.zip`.
- La API debe apuntar a las integraciones correctas.
- El rol IAM debe permitir `dynamodb:*` en este laboratorio.

## Puntos para estudiar
- DynamoDB usa `PAY_PER_REQUEST` para cobrar por uso.
- `hash_key` define la clave primaria.
- `boto3.resource("dynamodb")` conecta Python con DynamoDB.
- `json.loads(event["body"])` lee el cuerpo que llega por API Gateway.
- `source_code_hash` detecta cambios en el zip.

## Checklist rapido
- Si una Lambda no puede escribir, revisa su rol IAM.
- Si API Gateway no invoca, revisa `aws_lambda_permission`.
- Si la tabla no recibe datos, revisa la ruta y el body del request.
