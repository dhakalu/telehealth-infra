terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100"
    }
  }
  required_version = ">= 1.0.0"

    backend "s3" {
        bucket         = "common-tfstate-us-east-1"
        key            = "tfstate/terraform.tfstate"
        region         = "us-east-1"
        encrypt        = true
    }
}

provider "aws" {
    region = "us-east-1"
}