# Laboratorio API REST con Lambda

## Objetivo
Este proyecto crea una API REST en API Gateway que invoca una Lambda en Python.
La Lambda responde a dos rutas:
- `GET /hello`
- `POST /saludar`

## Orden recomendado para entenderlo
1. `provider.tf`
2. `variables.tf`
3. `main.tf`
4. `lambda_function.py`
5. `outputs.tf`

## Que hace cada parte
### `provider.tf`
Define la version minima de Terraform y el provider AWS. Tambien fija la region con `var.aws_region`.

### `variables.tf`
Contiene la variable `aws_region`, que permite cambiar la region sin tocar el codigo principal.

### `main.tf`
Aqui esta toda la infraestructura:
- `aws_iam_role`: rol que Lambda asume para ejecutarse.
- `aws_iam_role_policy_attachment`: permiso basico para escribir logs.
- `aws_lambda_function`: funcion que ejecuta el archivo `lambda_function.py` empaquetado en `lambda.zip`.
- `aws_api_gateway_rest_api`: crea la API.
- `aws_api_gateway_resource`: define las rutas `/hello` y `/saludar`.
- `aws_api_gateway_method`: define los metodos HTTP permitidos.
- `aws_api_gateway_integration`: conecta cada metodo con la Lambda.
- `aws_lambda_permission`: permite que API Gateway invoque la Lambda.
- `aws_api_gateway_deployment`: publica la API.
- `aws_api_gateway_stage`: expone la version `dev`.

### `lambda_function.py`
Contiene la logica que responde a los requests.
- `_response()` construye la salida para API Gateway.
- `_parse_body()` lee y decodifica el body.
- `_extract_nombre()` valida el campo `nombre`.
- `lambda_handler()` decide que devolver segun ruta y metodo.

### `outputs.tf`
Imprime las URLs publicas de `GET /hello` y `POST /saludar`.

## Orden de creacion en Terraform
1. Crear el rol de IAM.
2. Adjuntar la politica basica de logs.
3. Crear la Lambda.
4. Crear la API REST.
5. Crear los recursos `/hello` y `/saludar`.
6. Crear los metodos GET y POST.
7. Crear las integraciones con Lambda.
8. Dar permiso a API Gateway para invocar la Lambda.
9. Crear el deployment.
10. Crear el stage `dev`.
11. Revisar los outputs.

## Que debe tener para funcionar
- Un archivo `lambda.zip` valido con `lambda_function.py` dentro.
- Permisos de IAM para ejecutar Lambda y escribir logs.
- API Gateway con integracion `AWS_PROXY`.
- Deployment y stage creados.

## Puntos para estudiar
- `AWS_PROXY` hace que API Gateway mande el evento casi completo a Lambda.
- `depends_on` ayuda a evitar que el deployment salga antes de tiempo.
- `source_code_hash` fuerza redeploy cuando cambia el zip.
- El stage `dev` es la URL que vas a probar.

## Checklist rapido
- Si cambias la Lambda, reconstruye `lambda.zip`.
- Si cambias rutas o metodos, Terraform debe redeployar la API.
- Si falla el log, revisa la politica `AWSLambdaBasicExecutionRole`.
