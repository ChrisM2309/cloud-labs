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
