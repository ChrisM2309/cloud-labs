terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Define la version minima de Terraform y el provider AWS que se usara.
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  # PROVEEDOR AWS
  # Esta region controla donde se crean los recursos del laboratorio.
  region = var.aws_region
}
