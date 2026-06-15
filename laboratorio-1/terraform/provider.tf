terraform {
  # CONFIGURACION BASE DE TERRAFORM
  # Define la version minima de Terraform y el provider AWS.
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
  # Region donde se creara el bucket de S3.
  region = var.aws_region
}
