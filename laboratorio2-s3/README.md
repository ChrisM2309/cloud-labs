# Laboratorio 2: Sitio web estatico en S3

## Objetivo
Este proyecto publica una pagina web estatica directamente desde un bucket S3.

## Orden recomendado para entenderlo
1. `provider.tf`
2. `main.tf`
3. `index.html`
4. `outputs.tf`

## Que hace cada parte
### `provider.tf`
Configura AWS como provider y fija la region `us-east-1`.

### `main.tf`
Aqui se arma el sitio:
- `aws_s3_bucket`: crea el bucket.
- `aws_s3_bucket_website_configuration`: activa hosting web.
- `aws_s3_bucket_public_access_block`: permite acceso publico.
- `aws_s3_bucket_policy`: autoriza lectura publica de objetos.
- `aws_s3_object`: sube el archivo `index.html`.

### `index.html`
Es el contenido real de la pagina web.

### `outputs.tf`
Devuelve el endpoint web del bucket.

## Orden de creacion en Terraform
1. Crear el bucket.
2. Habilitar el website hosting.
3. Ajustar el bloqueo de acceso publico.
4. Crear la policy publica de lectura.
5. Subir el `index.html`.
6. Revisar la URL final.

## Que debe tener para funcionar
- Bucket con nombre unico global.
- Website configuration activa.
- Politica publica que permita `s3:GetObject`.
- Objeto `index.html` cargado.

## Puntos para estudiar
- El bucket es el almacenamiento.
- La website configuration transforma S3 en hosting web.
- La policy publica es necesaria para que cualquier usuario vea la pagina.
- El `output` facilita copiar la URL despues del deploy.

## Checklist rapido
- Si la pagina no abre, revisa la policy publica.
- Si el index no carga, revisa el `website_configuration`.
- Si el bucket ya existe, cambia el nombre.
