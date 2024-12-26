terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
  backend "s3" {
    bucket = "terraform-fargate-vpcep"
    key    = "terraform/terraform.tfstate"
    region = "us-west-2"
  }
}
