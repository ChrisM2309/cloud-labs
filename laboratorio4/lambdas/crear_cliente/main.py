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
