terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Se usa AWS como provider para desplegar S3 + CloudFront.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # CloudFront es global, pero el origen S3 de este laboratorio vive en us-east-1.
  region = "us-east-1"
}
