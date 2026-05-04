terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  backend "s3" {
    bucket         = "remote-state-h1"
    key            = "compute/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

    required_version = ">= 1.2"

}





