resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-ecs-sg"
  description = "Security group for ${var.project_name}"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "From anywhere inside VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main_vpc.cidr_block]
  }

  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }
}

resource "aws_iam_policy" "task_execution" {
  name        = "${var.project_name}-task"
  description = "Task ${var.project_name} policy for Fargate"
  tags        = local.tags
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "CloudwatchPutLogs",
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups"
        ],
        Resource = [
          aws_cloudwatch_log_group.log_group.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role" "task_execution" {
  assume_role_policy = data.aws_iam_policy_document.host_execution_assume_role.json
  name               = "${var.project_name}-task-role"
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  policy_arn = aws_iam_policy.task_execution.arn
  role       = aws_iam_role.task_execution.name
}

data "aws_iam_policy_document" "host_execution_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "host_execution_policy" {
  policy = data.aws_iam_policy_document.host_execution_policy.json
  name   = "fargate-ecr-link"

  tags = local.tags
}

data "aws_iam_policy_document" "host_execution_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "host_execution_role" {
  assume_role_policy = data.aws_iam_policy_document.host_execution_assume_role.json
  name               = "fargate-ecr-link"
}

resource "aws_iam_role_policy_attachment" "host_execution_role_attachment" {
  policy_arn = aws_iam_policy.host_execution_policy.arn
  role       = aws_iam_role.host_execution_role.name
}

resource "aws_ecs_cluster" "default" {
  name = "${var.project_name}-ecs-cluster"
}

resource "aws_ecs_task_definition" "default" {
  family                   = var.project_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.host_execution_role.arn
  task_role_arn            = aws_iam_role.task_execution.arn

  tags = local.tags

  container_definitions = jsonencode([{
    name      = "${var.project_name}-container"
    image     = "${aws_ecr_repository.default.repository_url}:${var.container_version}"
    essential = true
    portMappings = [{
      protocol      = "tcp"
      containerPort = 80
      hostPort      = 80
    }]
    environment = [
      { name = "ENVIRONMENT", value = "Production" },
      { name = "LOG_GROUP_NAME", value = aws_cloudwatch_log_group.log_group.name }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.log_group.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "default" {
  name                 = "${var.project_name}-ecs-service"
  cluster              = aws_ecs_cluster.default.id
  task_definition      = aws_ecs_task_definition.default.arn
  desired_count        = 1
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  force_new_deployment = true

  tags = local.tags

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.default.arn
    container_name   = "${var.project_name}-container"
    container_port   = "80"
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}
