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
