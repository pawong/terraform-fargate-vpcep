provider "aws" {
  region = var.region
}

locals {
  tags = {
    app = "${var.project_name}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
