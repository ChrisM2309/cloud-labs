terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Define el provider AWS que usara este laboratorio.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # Region donde se creara la base de datos, Lambda y API Gateway.
  region = var.region
}
