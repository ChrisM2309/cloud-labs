# Laboratorio 1: Base de acceso a AWS + Terraform para S3

## Objetivo
Este laboratorio sirve como base inicial para:
- configurar acceso a AWS con IAM y AWS CLI
- verificar acceso a S3
- crear un proyecto Terraform
- inicializar y validar Terraform

## Que implementa este proyecto
La implementacion de apoyo para el laboratorio 1 crea un bucket S3 base con:
- nombre generado por prefijo para evitar conflictos
- bloqueo de acceso publico activado
- versionado habilitado
- cifrado del lado del servidor habilitado

## Orden recomendado para entenderlo
1. `terraform/provider.tf`
2. `terraform/variables.tf`
3. `terraform/main.tf`
4. `terraform/outputs.tf`

## Que hace cada parte
### `terraform/provider.tf`
Define la version minima de Terraform y el provider AWS.

### `terraform/variables.tf`
Contiene la region AWS y el prefijo del bucket.

### `terraform/main.tf`
Aqui se crea el bucket y se le agregan controles basicos de seguridad.

### `terraform/outputs.tf`
Muestra el nombre y ARN del bucket generado.

## Orden de creacion en Terraform
1. Configurar el provider.
2. Definir las variables.
3. Crear el bucket S3.
4. Activar public access block.
5. Activar versioning.
6. Activar encryption.
7. Revisar los outputs.

## Que debes practicar con este laboratorio
- `terraform init`
- `terraform validate`
- lectura de recursos `aws_s3_bucket`
- lectura de recursos complementarios de S3

## Puntos para estudiar
- `bucket_prefix` permite que AWS agregue un sufijo unico.
- `public_access_block` ayuda a dejar el bucket privado.
- `versioning` permite mantener historial de objetos.
- `server_side_encryption` protege los datos almacenados.

## Relacion con el PDF
El PDF del laboratorio 1 se enfoca en preparar el entorno:
- entrar a IAM
- crear usuario
- generar access keys
- configurar AWS CLI
- verificar acceso a S3
- crear el proyecto Terraform
- inicializar y validar Terraform

Este proyecto complementa esa parte con una base real de infraestructura en S3.
