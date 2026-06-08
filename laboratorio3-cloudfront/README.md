# Laboratorio 3: S3 con CloudFront

## Objetivo
Este proyecto toma un sitio estatico alojado en S3 y lo distribuye por CloudFront.

## Orden recomendado para entenderlo
1. `provider.tf`
2. `variables.tf`
3. `terraform.tfvars`
4. `main.tf`
5. `index.html`
6. `style.css`
7. `outputs.tf`

## Que hace cada parte
### `provider.tf`
Configura AWS en `us-east-1`, region usada por el bucket origen.

### `variables.tf`
Define `bucket_name`, que apunta al bucket origen existente.

### `terraform.tfvars`
Asigna el nombre concreto del bucket.

### `main.tf`
Aqui pasan dos cosas:
- Se suben `index.html`, `style.css` y `logo.png` al bucket.
- Se crea una distribucion `aws_cloudfront_distribution`.

### `index.html`
Es la pagina principal del sitio.

### `style.css`
Es la hoja de estilos.

### `outputs.tf`
Devuelve el dominio de CloudFront.

## Orden de creacion en Terraform
1. Definir el bucket origen con `bucket_name`.
2. Subir los objetos estaticos al bucket.
3. Crear el `origin` de CloudFront.
4. Configurar el `default_cache_behavior`.
5. Configurar la restriccion geografica.
6. Habilitar el certificado por defecto de CloudFront.
7. Revisar el dominio generado.

## Que debe tener para funcionar
- Bucket S3 ya existente.
- Sitio web del bucket accesible por endpoint de website.
- Objetos `index.html`, `style.css` y `logo.png`.
- Distribucion CloudFront apuntando al origin correcto.

## Puntos para estudiar
- CloudFront mejora entrega y cache.
- `viewer_protocol_policy = "redirect-to-https"` obliga a usar HTTPS.
- `default_root_object = "index.html"` define la pagina inicial.
- El `origin` usa el endpoint website de S3, no el endpoint normal del bucket.

## Checklist rapido
- Si la imagen no aparece, revisa que `logo.png` este en el bucket.
- Si el CSS no carga, revisa que `style.css` se haya subido.
- Si CloudFront no abre, revisa el `origin` y el bucket origen.
