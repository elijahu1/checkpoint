terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.41.0"
    }
  }

    backend "s3" {
    bucket         = "remote-state-h1"
    key            = "storage/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }


    required_version = ">= 1.2"

}

