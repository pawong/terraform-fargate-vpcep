resource "aws_vpc" "main_vpc" {
  cidr_block           = "11.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_security_group" "vpcep_sg" {
  name        = "vpcep-${var.project_name}-sg"
  description = "Security group for ${var.project_name}"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "From anywhere inside VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main_vpc.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_vpc.main_vpc.default_route_table_id]
  tags = {
    Name = "${var.project_name}-s3-ep"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_id              = aws_vpc.main_vpc.id
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpcep_sg.id]
  subnet_ids          = aws_subnet.private.*.id
  tags = {
    Name = "${var.project_name}-ssm-ep"
  }
}

resource "aws_vpc_endpoint" "cloudwatch" {
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_id              = aws_vpc.main_vpc.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpcep_sg.id]
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  tags = {
    Name = "${var.project_name}-logs-ep"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_id              = aws_vpc.main_vpc.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpcep_sg.id]
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  tags = {
    Name = "${var.project_name}-ecr-api-ep"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_id              = aws_vpc.main_vpc.id
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpcep_sg.id]
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private.*.id
  tags = {
    Name = "${var.project_name}-ecr-dkr-ep"
  }
}
