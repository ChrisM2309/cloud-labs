variable "aws_region" {
  # VARIABLE TIPO: AWS_REGION
  # Region donde se desplegara el laboratorio.
  description = "Region AWS donde se desplegara el laboratorio 1"
  type        = string
  default     = "us-east-1"
}

variable "bucket_prefix" {
  # VARIABLE TIPO: BUCKET_PREFIX
  # Prefijo usado para generar un nombre unico de bucket S3.
  description = "Prefijo del bucket S3"
  type        = string
  default     = "laboratorio1-terraform-"
}
