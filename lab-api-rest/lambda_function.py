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
