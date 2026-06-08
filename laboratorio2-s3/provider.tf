terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Este laboratorio usa AWS como provider principal.
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # Se fija la region donde vivira el bucket y sus objetos.
  region = "us-east-1"
}
