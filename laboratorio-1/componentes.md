# Componentes - Laboratorio 1

Este laboratorio es la base del repo. Aqui estudias:
- acceso a AWS con IAM y AWS CLI
- validacion con `terraform init` y `terraform validate`
- creacion de un bucket S3 con seguridad basica

## Orden de estudio
1. `terraform/provider.tf`
2. `terraform/variables.tf`
3. `terraform/main.tf`
4. `terraform/outputs.tf`

## Requisito general
Antes de correr Terraform debes tener:
- una cuenta AWS activa
- un usuario IAM con access keys
- AWS CLI configurado
- permisos para crear S3

## COMPONENTE OPERATIVO: IAM + AWS CLI + TERRAFORM

- Descripcion: preparacion previa al despliegue.
- Uso: entrar a AWS, crear usuario, generar credenciales, configurar CLI y validar acceso.
- Necesidades: cuenta AWS y permisos IAM.
- Requisitos: `aws configure` funcionando y acceso a S3.
- Campos a modificar: region, usuario, access key y secret key.
- Codigo base:

```bash
aws configure
aws s3 ls
terraform init
terraform validate
```

## COMPONENTE TIPO: PROVIDER AWS

- Descripcion: conecta Terraform con AWS.
- Uso: define version minima de Terraform, provider AWS y region.
- Necesidades: credenciales AWS listas.
- Requisitos: el provider debe coincidir con la version usada en el laboratorio.
- Campos a modificar: `required_version`, version del provider y `region`.
- Dependencias: todas las demas.
- Codigo base:

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

## COMPONENTE TIPO: VARIABLE AWS_REGION

- Descripcion: region donde se crea la infraestructura.
- Uso: permite cambiar la region sin tocar el provider.
- Necesidades: ninguna.
- Requisitos: la region debe existir en AWS.
- Campos a modificar: `default`.
- Dependencias: provider y outputs.
- Codigo base:

```hcl
variable "aws_region" {
  description = "Region AWS donde se desplegara el laboratorio 1"
  type        = string
  default     = "us-east-1"
}
```

## COMPONENTE TIPO: VARIABLE BUCKET_PREFIX

- Descripcion: prefijo para el bucket S3.
- Uso: evita conflictos porque S3 requiere nombres unicos.
- Necesidades: ninguna.
- Requisitos: el prefijo debe ser claro y reconocible.
- Campos a modificar: `default`.
- Dependencias: `aws_s3_bucket`.
- Codigo base:

```hcl
variable "bucket_prefix" {
  description = "Prefijo del bucket S3"
  type        = string
  default     = "laboratorio1-terraform-"
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET

- Descripcion: bucket principal del laboratorio.
- Uso: almacena los objetos de S3.
- Necesidades: provider AWS y permisos S3.
- Requisitos: el nombre debe ser unico.
- Campos a modificar: `bucket_prefix` o `bucket`.
- Dependencias: public access block, versioning, encryption y outputs.
- Codigo base:

```hcl
resource "aws_s3_bucket" "laboratorio1" {
  bucket_prefix = var.bucket_prefix
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET_PUBLIC_ACCESS_BLOCK

- Descripcion: bloquea el acceso publico.
- Uso: deja el bucket privado por defecto.
- Necesidades: el bucket debe existir.
- Requisitos: definir bien los 4 flags.
- Campos a modificar: `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_bucket_public_access_block" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET_VERSIONING

- Descripcion: versionado de S3.
- Uso: conserva historial de objetos.
- Necesidades: bucket creado.
- Requisitos: `status = "Enabled"` para activarlo.
- Campos a modificar: `status`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_bucket_versioning" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

## COMPONENTE TIPO: RECURSO AWS_S3_BUCKET_SERVER_SIDE_ENCRYPTION_CONFIGURATION

- Descripcion: cifrado del lado del servidor.
- Uso: protege la informacion guardada.
- Necesidades: bucket creado.
- Requisitos: elegir algoritmo compatible.
- Campos a modificar: `sse_algorithm`.
- Dependencias: bucket.
- Codigo base:

```hcl
resource "aws_s3_bucket_server_side_encryption_configuration" "laboratorio1" {
  bucket = aws_s3_bucket.laboratorio1.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

## COMPONENTE TIPO: OUTPUTS

- Descripcion: resultados utiles del despliegue.
- Uso: muestra nombre y ARN del bucket.
- Necesidades: el bucket ya debe existir.
- Requisitos: mantener salidas simples y claras.
- Campos a modificar: `value` y `description`.
- Dependencias: bucket.
- Codigo base:

```hcl
output "bucket_name" {
  value = aws_s3_bucket.laboratorio1.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.laboratorio1.arn
}
```

## Resumen rapido
- `provider` conecta Terraform con AWS.
- `bucket_prefix` evita nombres duplicados.
- `public_access_block` mantiene privado el bucket.
- `versioning` guarda versiones anteriores.
- `encryption` protege la informacion.
- `outputs` te muestran el resultado final.
